import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule.dart';

/// DatabaseHelper
/// ----------------------------------------------------------------------
/// SQLite cache for the in-bus tablet. Each row is keyed by both
/// schedule_id AND driver_id, so multiple drivers can share the same
/// tablet without seeing each other's trips.
///
/// Schema v2 adds the `driver_id` column. The onUpgrade callback handles
/// users coming from v1 (no driver_id) — it drops and recreates the
/// table. Anyone in production would migrate the data instead, but for
/// a tablet that re-downloads from the server every boot this is fine.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static Database? _db;
  static const int _dbVersion = 2;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_bus.db');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        await _createTable(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // Schema change: drop and recreate. The cache is rebuilt from
        // the server on the next boot anyway.
        await db.execute('DROP TABLE IF EXISTS schedules');
        await _createTable(db);
      },
    );
  }

  Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE schedules (
        schedule_id     INTEGER NOT NULL,
        driver_id       INTEGER NOT NULL,
        schedule_date   TEXT NOT NULL,
        expected_start  TEXT NOT NULL,
        expected_end    TEXT NOT NULL,
        actual_start    TEXT,
        actual_end      TEXT,
        job_status      TEXT NOT NULL DEFAULT 'Pending',
        is_synced       INTEGER NOT NULL DEFAULT 1,
        route_name      TEXT,
        origin          TEXT,
        destination     TEXT,
        plate_number    TEXT,
        driver_name     TEXT,
        PRIMARY KEY (schedule_id, driver_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_unsynced ON schedules(is_synced)');
    await db.execute('CREATE INDEX idx_driver   ON schedules(driver_id)');
  }

  // ------------------------------------------------------------------
  // Cache schedules for a specific driver.
  // ------------------------------------------------------------------
  Future<void> cacheItinerary(int driverId, List<Schedule> list) async {
    final db = await database;
    final batch = db.batch();
    for (final s in list) {
      // Preserve local unsynced edits: only overwrite rows whose local
      // copy is already synced.
      final existing = await db.query(
        'schedules',
        where: 'schedule_id = ? AND driver_id = ?',
        whereArgs: [s.scheduleId, driverId],
        limit: 1,
      );
      if (existing.isEmpty || (existing.first['is_synced'] as int) == 1) {
        final row = s.toDbMap()..['driver_id'] = driverId;
        batch.insert('schedules', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  /// Get schedules for one specific driver only.
  Future<List<Schedule>> getByDriver(int driverId) async {
    final db = await database;
    final rows = await db.query(
      'schedules',
      where: 'driver_id = ?',
      whereArgs: [driverId],
      orderBy: 'expected_start ASC',
    );
    return rows.map(Schedule.fromDb).toList();
  }

  Future<void> markStarted(int scheduleId, int driverId, String ts) async {
    final db = await database;
    await db.update(
      'schedules',
      {'actual_start': ts, 'job_status': 'In-Progress', 'is_synced': 0},
      where: 'schedule_id = ? AND driver_id = ?',
      whereArgs: [scheduleId, driverId],
    );
  }

  Future<void> markEnded(int scheduleId, int driverId, String ts) async {
    final db = await database;
    await db.update(
      'schedules',
      {'actual_end': ts, 'job_status': 'Completed', 'is_synced': 0},
      where: 'schedule_id = ? AND driver_id = ?',
      whereArgs: [scheduleId, driverId],
    );
  }

  /// ALL unsynced rows across ALL drivers — used by SyncService so that
  /// data from a previously-logged-in driver gets pushed too. Critical
  /// for the "shift change" scenario where Driver A left without syncing.
  Future<List<Schedule>> getAllUnsynced() async {
    final db = await database;
    final rows = await db.query('schedules', where: 'is_synced = 0');
    return rows.map(Schedule.fromDb).toList();
  }

  /// Unsynced rows for ONE driver — used at logout to decide if sync
  /// must happen before allowing the switch.
  Future<List<Schedule>> getUnsyncedByDriver(int driverId) async {
    final db = await database;
    final rows = await db.query(
      'schedules',
      where: 'is_synced = 0 AND driver_id = ?',
      whereArgs: [driverId],
    );
    return rows.map(Schedule.fromDb).toList();
  }

  /// Mark the given (schedule, driver) pairs as synced.
  Future<void> markSyncedBatch(List<(int, int)> pairs) async {
    if (pairs.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final p in pairs) {
      batch.update(
        'schedules',
        {'is_synced': 1},
        where: 'schedule_id = ? AND driver_id = ?',
        whereArgs: [p.$1, p.$2],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Remove a driver's rows from the cache. Called after a confirmed
  /// successful sync at logout time, so the next driver sees a clean slate.
  Future<void> clearForDriver(int driverId) async {
    final db = await database;
    await db.delete('schedules', where: 'driver_id = ?', whereArgs: [driverId]);
  }

  /// Reconcile the local cache with a fresh list from the server.
  ///
  /// SAFETY GUARDS:
  ///   - If server returns 0 trips → DO NOTHING. Almost always a query/date
  ///     mismatch, not an actual mass-deletion. Refuse to wipe the cache.
  ///   - Unsynced rows (is_synced = 0) are NEVER touched.
  ///   - Started/completed rows (actual_start IS NOT NULL) are NEVER touched.
  ///
  /// Rules for the rest:
  ///   - Server trip is NEW (not in cache) → add it.
  ///   - Server trip matches a synced+not-started cached row → overwrite
  ///     from server (catches supervisor edits to times/route/etc.)
  ///   - Cached row not in server list, synced and not started → remove
  ///     (supervisor deleted a Pending trip the driver hasn't touched).
  ///
  /// Returns the count of changes made.
  Future<int> reconcileFromServer(int driverId, List<Schedule> serverList) async {
    // SAFETY: refuse to reconcile against an empty server list.
    // An empty result almost always means the server query missed the date
    // (timezone, stale test data, etc.) rather than a real mass-delete.
    if (serverList.isEmpty) return 0;

    final db = await database;
    int changes = 0;

    // Map server trips by ID for quick lookup.
    final serverById = {for (final s in serverList) s.scheduleId: s};

    // Load existing cache for this driver.
    final cached = await db.query(
      'schedules',
      where: 'driver_id = ?',
      whereArgs: [driverId],
    );

    final batch = db.batch();

    // 1. Add / update from server.
    for (final s in serverList) {
      final existing = cached.where((r) => r['schedule_id'] == s.scheduleId);
      if (existing.isEmpty) {
        // Brand new trip from server — add it.
        final row = s.toDbMap()..['driver_id'] = driverId;
        batch.insert('schedules', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
        changes++;
      } else {
        final row = existing.first;
        final isSynced = (row['is_synced'] as int) == 1;
        final hasStart = row['actual_start'] != null;
        // Only overwrite synced + not-started rows.
        if (isSynced && !hasStart) {
          batch.update(
            'schedules',
            s.toDbMap()..['driver_id'] = driverId,
            where: 'schedule_id = ? AND driver_id = ?',
            whereArgs: [s.scheduleId, driverId],
          );
          changes++;
        }
      }
    }

    // 2. Remove cached rows the server didn't return — but ONLY rows that
    // share a date with the server's results. If the server returned trips
    // for May 14 and we have a cached trip for May 13, that's a different
    // query, not a deletion. Leave it alone.
    final serverDates = serverList.map((s) => s.scheduleDate).toSet();
    for (final row in cached) {
      final id   = row['schedule_id'] as int;
      final date = row['schedule_date'] as String;
      if (serverById.containsKey(id))   continue;   // still there, keep
      if (!serverDates.contains(date))  continue;   // out of query window, keep

      final isSynced = (row['is_synced'] as int) == 1;
      final hasStart = row['actual_start'] != null;
      if (isSynced && !hasStart) {
        batch.delete(
          'schedules',
          where: 'schedule_id = ? AND driver_id = ?',
          whereArgs: [id, driverId],
        );
        changes++;
      }
    }

    await batch.commit(noResult: true);
    return changes;
  }
}
