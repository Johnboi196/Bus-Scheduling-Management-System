import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';

/// ApiService
/// ----------------------------------------------------------------------
/// Single point of contact with the CodeIgniter backend.
/// Change [baseUrl] to your XAMPP machine's LAN IP so the tablet can
/// reach it (e.g. http://192.168.1.50/smart_bus/public/api).
class ApiService {
  /// IMPORTANT: when running on a real tablet you CANNOT use "localhost"
  /// or "127.0.0.1" — those resolve to the tablet itself. Use the
  /// laptop/server's LAN IP. For the Android emulator, use 10.0.2.2.
  // static const String baseUrl = 'http://10.0.2.2/ci4/public/api';
     static const String baseUrl = 'http://10.0.2.2/api';
  //static const String baseUrl = 'http://192.168.68.102/api';

  static const Duration _timeout = Duration(seconds: 10);

  // ------------------------------------------------------------------
  // DRIVER PROFILE — fetched on Profile screen load
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchDriverProfile(int driverId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/driver/profile/$driverId'),
      ).timeout(_timeout);

      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['driver'] as Map?)?.cast<String, dynamic>();
    } catch (e) {
      return null;
    }
  }
  // ------------------------------------------------------------------
  // TRIP HISTORY — completed trips for the History screen
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchTripHistory(int driverId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/schedule/history/$driverId'),
      ).timeout(_timeout);

      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  // ------------------------------------------------------------------
  // AUTH
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String role = 'driver',
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password, 'role': role}),
        )
        .timeout(_timeout);

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(body['messages']?['error'] ?? body['message'] ?? 'Login failed');
    }
    return body;
  }

  // ------------------------------------------------------------------
  // SCHEDULE — Sequence Diagram step 3
  // ------------------------------------------------------------------
  Future<List<Schedule>> fetchDailyScheduleByMac(String mac, {int? driverId}) async {
    // Append ?driver_id=N when we know who's logged in so the API filters
    // to just their trips. Multiple drivers can share the same bus tablet
    // throughout the day.
    final uri = Uri.parse('$baseUrl/schedule/byMac/$mac'
        '${driverId != null ? '?driver_id=$driverId' : ''}');
    final res = await http.get(uri).timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Server returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['schedules'] as List).cast<Map<String, dynamic>>();
    return list.map(Schedule.fromApi).toList();
  }

  // ------------------------------------------------------------------
  // ONLINE Start/End — Sequence Diagram step 4 "[Connected]" branch
  // ------------------------------------------------------------------
  Future<bool> updateTripStatus({
    required int scheduleId,
    String? actualStart,
    String? actualEnd,
    required String jobStatus,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/schedule/updateStatus'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'schedule_id':  scheduleId,
            'actual_start': actualStart,
            'actual_end':   actualEnd,
            'job_status':   jobStatus,
          }),
        )
        .timeout(_timeout);
    return res.statusCode == 200;
  }

  // ------------------------------------------------------------------
  // BULK SYNC — Sequence Diagram step 5
  // ------------------------------------------------------------------
  Future<bool> pushCacheData(List<Schedule> unsynced) async {
    if (unsynced.isEmpty) return true;
    final res = await http
        .post(
          Uri.parse('$baseUrl/sync/push'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'trips': unsynced.map((s) => s.toSyncJson()).toList(),
          }),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['status'] == 'success';
  }

  // ------------------------------------------------------------------
  // OVERTIME
  // ------------------------------------------------------------------
  Future<bool> submitOvertime({
    required int scheduleId,
    required int extraMinutes,
    String reason = '',
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/overtime/request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'schedule_id':   scheduleId,
            'extra_minutes': extraMinutes,
            'reason':        reason,
          }),
        )
        .timeout(_timeout);
    return res.statusCode == 200;
  }

  // ------------------------------------------------------------------
  // CANCEL REQUEST — driver wants to drop a trip
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>> requestCancel({
    required int scheduleId,
    required int driverId,
    String reason = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/cancel/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'schedule_id': scheduleId,
        'driver_id':   driverId,
        'reason':      reason,
      }),
    ).timeout(_timeout);

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(body['messages']?['error'] ?? body['message'] ?? 'Submit failed');
    }
    return body;
  }

  // ------------------------------------------------------------------
  // VOLUNTEER — list available trips & submit a volunteer request
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchAvailableTrips(int driverId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/volunteer/available?driver_id=$driverId'),
    ).timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Server returned ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> volunteerForTrip({
    required int scheduleId,
    required int driverId,
    String note = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/volunteer/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'schedule_id': scheduleId,
        'driver_id':   driverId,
        'note':        note,
      }),
    ).timeout(_timeout);

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(body['messages']?['error'] ?? body['message'] ?? 'Submit failed');
    }
    return body;
  }
}
