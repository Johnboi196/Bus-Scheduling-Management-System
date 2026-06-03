/// Schedule model — one trip the driver must perform.
class Schedule {
  final int    scheduleId;
  final int    driverId;          // ← NEW: tracks which driver owns this row
  final String scheduleDate;
  final String expectedStart;
  final String expectedEnd;
  String?      actualStart;
  String?      actualEnd;
  String       jobStatus;
  int          isSynced;
  final String routeName;
  final String origin;
  final String destination;
  final String plateNumber;
  final String driverName;

  Schedule({
    required this.scheduleId,
    required this.driverId,
    required this.scheduleDate,
    required this.expectedStart,
    required this.expectedEnd,
    this.actualStart,
    this.actualEnd,
    required this.jobStatus,
    required this.isSynced,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.plateNumber,
    required this.driverName,
  });

  factory Schedule.fromApi(Map<String, dynamic> j) => Schedule(
        scheduleId:   _asInt(j['schedule_id']),
        driverId:     _asInt(j['driver_id']),
        scheduleDate: j['schedule_date']?.toString() ?? '',
        expectedStart:j['expected_start']?.toString() ?? '',
        expectedEnd:  j['expected_end']?.toString()   ?? '',
        actualStart:  j['actual_start']?.toString(),
        actualEnd:    j['actual_end']?.toString(),
        jobStatus:    j['job_status']?.toString() ?? 'Pending',
        isSynced:     _asInt(j['is_synced'], def: 1),
        routeName:    j['route_name']?.toString()  ?? '',
        origin:       j['origin']?.toString()      ?? '',
        destination:  j['destination']?.toString() ?? '',
        plateNumber:  j['plate_number']?.toString()?? '',
        driverName:   j['driver_name']?.toString() ?? '',
      );

  factory Schedule.fromDb(Map<String, dynamic> m) => Schedule(
        scheduleId:   m['schedule_id']   as int,
        driverId:     m['driver_id']     as int,
        scheduleDate: m['schedule_date'] as String,
        expectedStart:m['expected_start']as String,
        expectedEnd:  m['expected_end']  as String,
        actualStart:  m['actual_start']  as String?,
        actualEnd:    m['actual_end']    as String?,
        jobStatus:    m['job_status']    as String,
        isSynced:     m['is_synced']     as int,
        routeName:    m['route_name']    as String? ?? '',
        origin:       m['origin']        as String? ?? '',
        destination:  m['destination']   as String? ?? '',
        plateNumber:  m['plate_number']  as String? ?? '',
        driverName:   m['driver_name']   as String? ?? '',
      );

  /// Used by DatabaseHelper.cacheItinerary (it injects driver_id explicitly).
  Map<String, dynamic> toDbMap() => {
        'schedule_id':    scheduleId,
        'driver_id':      driverId,
        'schedule_date':  scheduleDate,
        'expected_start': expectedStart,
        'expected_end':   expectedEnd,
        'actual_start':   actualStart,
        'actual_end':     actualEnd,
        'job_status':     jobStatus,
        'is_synced':      isSynced,
        'route_name':     routeName,
        'origin':         origin,
        'destination':    destination,
        'plate_number':   plateNumber,
        'driver_name':    driverName,
      };

  Map<String, dynamic> toSyncJson() => {
        'schedule_id':  scheduleId,
        'actual_start': actualStart,
        'actual_end':   actualEnd,
        'job_status':   jobStatus,
      };

  static int _asInt(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? def;
  }
}
