import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../helpers/database_helper.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// SyncService
/// ----------------------------------------------------------------------
/// Background loop that keeps client and server in sync.
///
/// Each sync does TWO things in order:
///
///   1. PUSH: send the driver's unsynced START/END timestamps to server.
///   2. PULL: fetch the server's current schedule list, then reconcile
///            with the local cache (catching supervisor add/edit/delete).
///
/// The push-first order is critical. If we pulled first, we could
/// overwrite a not-yet-pushed local change. Always push first, then
/// the server has the authoritative state we can safely pull.
class SyncService {
  final ApiService _api = ApiService();
  final DatabaseHelper _db = DatabaseHelper.instance;

  Timer? _periodic;
  StreamSubscription? _connSub;
  bool _running = false;

  /// Status messages for the UI status bar.
  void Function(String msg)? onStatus;

  /// Called whenever the cache changed (added/updated/removed rows).
  /// TripScreen subscribes to this so it can reload its list.
  void Function()? onCacheChanged;

  /// Called once by TripScreen after it determines the device's MAC.
  /// Stored statically so all subsequent syncs use the same MAC without
  /// needing to re-prompt for location permission.
  static String? cachedMac;

  void start() {
    _periodic ??= Timer.periodic(
      const Duration(minutes: 5),
      (_) => trySync(reason: 'periodic'),
    );
    _connSub ??= Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any(_isOnlineResult);
      if (online) trySync(reason: 'connectivity-restored');
    });
  }

  void stop() {
    _periodic?.cancel();   _periodic = null;
    _connSub?.cancel();    _connSub  = null;
  }

  bool _isOnlineResult(ConnectivityResult r) =>
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet;

  /// Full sync: push unsynced changes, then pull latest from server.
  /// Safe to call any time. Won't run if already running.
  Future<void> trySync({String reason = 'manual'}) async {
    if (_running) return;
    _running = true;

    try {
      final results = await Connectivity().checkConnectivity();
      final online = results.any(_isOnlineResult);
      if (!online) {
        onStatus?.call('Offline — sync postponed.');
        return;
      }

      // ---------- STEP 1: PUSH unsynced status changes ----------
      final unsynced = await _db.getAllUnsynced();
      if (unsynced.isNotEmpty) {
        onStatus?.call('Pushing ${unsynced.length} trip(s)…');
        final ok = await _api.pushCacheData(unsynced);
        if (ok) {
          final pairs = unsynced
              .map((s) => (s.scheduleId, s.driverId))
              .toList();
          await _db.markSyncedBatch(pairs);
        } else {
          // Don't pull if push failed — the next attempt will retry.
          onStatus?.call('Server rejected sync — will retry.');
          return;
        }
      }

      // ---------- STEP 2: PULL latest schedules for current driver ----------
      final driverId = await AuthService.currentDriverId();
      if (driverId == null) {
        // No driver logged in (e.g. between sessions). Nothing more to do.
        onStatus?.call('Push complete. (No active driver to pull for.)');
        return;
      }

      onStatus?.call('Fetching latest schedule…');

      // Use the MAC that TripScreen detected at boot. If somehow it's
      // not set yet (sync fired before TripScreen finished bootstrapping),
      // skip the pull and try again next time.
      final mac = cachedMac;
      if (mac == null || mac.isEmpty) {
        onStatus?.call('Push complete. (MAC not ready, skipping pull.)');
        return;
      }

      try {
        final fresh = await _api.fetchDailyScheduleByMac(
          mac, driverId: driverId,
        );
        final changes = await _db.reconcileFromServer(driverId, fresh);

        if (changes > 0) {
          onStatus?.call('Schedule updated ($changes change'
              '${changes == 1 ? "" : "s"}).');
          onCacheChanged?.call();   // tell UI to reload from cache
        } else {
          onStatus?.call('Synced. No changes.');
        }
      } catch (e) {
        // Pull failed but push succeeded. That's not great but not fatal.
        onStatus?.call('Pushed OK. Pull failed: $e');
      }
    } catch (e) {
      onStatus?.call('Sync error: $e');
    } finally {
      _running = false;
    }
  }

  /// Logout-time sync: push only, must succeed. Returns false if not.
  /// We don't pull on logout — there's no UI to refresh anyway.
  Future<bool> syncDriverOrFail(int driverId) async {
    try {
      final results = await Connectivity().checkConnectivity();
      final online = results.any(_isOnlineResult);
      if (!online) {
        onStatus?.call('Cannot sync — offline.');
        return false;
      }

      final unsynced = await _db.getUnsyncedByDriver(driverId);
      if (unsynced.isEmpty) return true;

      onStatus?.call('Syncing ${unsynced.length} trip(s) before logout…');
      final ok = await _api.pushCacheData(unsynced);
      if (!ok) {
        onStatus?.call('Server rejected sync — try again.');
        return false;
      }
      final pairs = unsynced.map((s) => (s.scheduleId, s.driverId)).toList();
      await _db.markSyncedBatch(pairs);
      onStatus?.call('Synced. Safe to log out.');
      return true;
    } catch (e) {
      onStatus?.call('Sync error: $e');
      return false;
    }
  }
}
