import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helpers/database_helper.dart';
import '../models/schedule.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'login_screen.dart';

/// TripScreen — Schedule tab.
///
/// Logout has been moved to the Profile tab; this screen now only handles
/// trip display and start/end actions.
class TripScreen extends StatefulWidget {
  const TripScreen({super.key});
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final _api  = ApiService();
  final _db   = DatabaseHelper.instance;
  final _sync = SyncService();

  int?    _driverId;
  String? _driverName;
  List<Schedule> _schedules = [];
  String _statusBar = 'Booting…';
  bool   _loading = true;

  @override
  void initState() {
    super.initState();
    _sync.onStatus = (m) {
      if (mounted) setState(() => _statusBar = m);
    };
    // Auto-refresh the trip list whenever sync detects server changes.
    _sync.onCacheChanged = () async {
      if (_driverId == null || !mounted) return;
      final updated = await _db.getByDriver(_driverId!);
      if (mounted) setState(() => _schedules = updated);
    };
    _sync.start();
    _bootstrap();
  }

  @override
  void dispose() {
    _sync.stop();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);

    final driverId = await AuthService.currentDriverId();
    final driverName = await AuthService.currentDriverName();
    if (driverId == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
      return;
    }
    setState(() {
      _driverId = driverId;
      _driverName = driverName;
    });

    // Read MAC with location permission
    final info = NetworkInfo();
    String? mac;
    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        mac = await info.getWifiBSSID();
      }
    } catch (_) {/* ignore */}

    if (mac == null || mac.isEmpty || mac == '02:00:00:00:00:00') {
      mac = '02:00:00:00:00:00';
    }
    mac = mac.toUpperCase();
    debugPrint('═══ MAC: $mac · DRIVER: $driverId ($driverName) ═══');

    // Share the MAC with SyncService so background syncs use the same one.
    SyncService.cachedMac = mac;

    try {
      final online = await _isOnline();
      if (online) {
        setState(() => _statusBar = 'Fetching schedule for $driverName…');
        final remote = await _api.fetchDailyScheduleByMac(mac, driverId: driverId);
        await _db.reconcileFromServer(driverId, remote);
        setState(() => _statusBar =
            'Itinerary loaded (${remote.length} trip${remote.length==1?'':'s'})');
      } else {
        setState(() => _statusBar = 'Offline — using cached itinerary');
      }

      final cached = await _db.getByDriver(driverId);
      setState(() {
        _schedules = cached;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _statusBar = 'Boot error: $e — using cache only';
        _loading = false;
      });
      _schedules = await _db.getByDriver(driverId);
      setState(() {});
    }
  }

  Future<bool> _isOnline() async {
    final r = await Connectivity().checkConnectivity();
    return r.any((c) =>
        c == ConnectivityResult.wifi ||
        c == ConnectivityResult.mobile ||
        c == ConnectivityResult.ethernet);
  }

  String _now() {
    final n = DateTime.now();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)} '
           '${two(n.hour)}:${two(n.minute)}:${two(n.second)}';
  }

  Future<void> _startTrip(Schedule s) async {
    final ts = _now();
    await _db.markStarted(s.scheduleId, _driverId!, ts);
    s.actualStart = ts;
    s.jobStatus = 'In-Progress';
    s.isSynced = 0;
    setState(() {});

    if (await _isOnline()) {
      final ok = await _api.updateTripStatus(
        scheduleId: s.scheduleId, actualStart: ts, jobStatus: 'In-Progress',
      );
      if (ok) {
        await _db.markSyncedBatch([(s.scheduleId, _driverId!)]);
        s.isSynced = 1;
        setState(() => _statusBar = 'Trip ${s.scheduleId} started (synced).');
      } else {
        setState(() => _statusBar = 'Trip started — saved locally, will sync.');
      }
    } else {
      setState(() => _statusBar = 'Offline mode: status saved locally.');
    }
  }

  Future<void> _endTrip(Schedule s) async {
    final ts = _now();
    await _db.markEnded(s.scheduleId, _driverId!, ts);
    s.actualEnd = ts;
    s.jobStatus = 'Completed';
    s.isSynced = 0;
    setState(() {});

    if (await _isOnline()) {
      final ok = await _api.updateTripStatus(
        scheduleId: s.scheduleId, actualEnd: ts, jobStatus: 'Completed',
      );
      if (ok) {
        await _db.markSyncedBatch([(s.scheduleId, _driverId!)]);
        s.isSynced = 1;
      }
    }
    if (_isLate(s)) _promptOvertime(s);
  }

  bool _isLate(Schedule s) {
    if (s.actualEnd == null) return false;
    final actual = DateTime.tryParse(s.actualEnd!);
    final expected = DateTime.tryParse('${s.scheduleDate} ${s.expectedEnd}');
    if (actual == null || expected == null) return false;
    return actual.isAfter(expected.add(const Duration(minutes: 5)));
  }

  Future<void> _promptOvertime(Schedule s) async {
    final reasonCtrl = TextEditingController();
    final mins = DateTime.parse(s.actualEnd!)
        .difference(DateTime.parse('${s.scheduleDate} ${s.expectedEnd}'))
        .inMinutes;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Trip late by $mins minutes'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Reason for delay'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
          ElevatedButton(
            onPressed: () async {
              await _api.submitOvertime(
                scheduleId: s.scheduleId, extraMinutes: mins, reason: reasonCtrl.text,
              );
              if (mounted) {
                Navigator.pop(ctx);
                setState(() => _statusBar = 'Overtime request submitted.');
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_driverName != null
            ? 'Today · $_driverName'
            : 'Today\'s Itinerary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Force sync',
            onPressed: () => _sync.trySync(reason: 'user-tap'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.blueGrey.shade50,
            child: Text(_statusBar),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: () => _sync.trySync(reason: 'pull-to-refresh'),
              child: _schedules.isEmpty
                  ? ListView(   // must be scrollable for RefreshIndicator to work
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No trips assigned to you today.')),
                ],
              )
                  : ListView.separated(
                itemCount: _schedules.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (_, i) => _buildRow(_schedules[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Schedule s) {
    final notStarted = s.actualStart == null;
    final inProgress = s.actualStart != null && s.actualEnd == null;

    return ListTile(
      isThreeLine: true,
      title: Text('${s.routeName}  •  ${s.plateNumber}'),
      subtitle: Text(
        '${s.origin} → ${s.destination}\n'
        '${s.expectedStart} – ${s.expectedEnd}   '
        'Status: ${s.jobStatus}'
        '${s.isSynced == 0 ? "  (pending sync)" : ""}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (notStarted)
            ElevatedButton(
              onPressed: () => _startTrip(s),
              child: const Text('START'),
            )
          else if (inProgress)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _endTrip(s),
              child: const Text('END'),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green),

          // Overflow menu: only show "Request cancel" for not-started trips.
          if (notStarted)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'cancel') _promptCancel(s);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Request cancel'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Prompt for cancel reason and submit. Backend tracks it as a pending
  /// request — supervisor approves to actually unassign the trip.
  Future<void> _promptCancel(Schedule s) async {
    if (_driverId == null) return;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request to cancel trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.routeName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${s.origin} → ${s.destination}',
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g. Sick, family emergency, conflict…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your supervisor will review this request. The trip stays '
              'assigned to you until they approve the cancellation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.requestCancel(
        scheduleId: s.scheduleId,
        driverId:   _driverId!,
        reason:     reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cancellation request submitted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
