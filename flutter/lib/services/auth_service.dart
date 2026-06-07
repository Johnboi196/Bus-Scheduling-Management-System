import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService
/// ----------------------------------------------------------------------
/// Tracks the currently logged-in driver AND a list of recent drivers
/// so we can show quick-switch chips on the login screen.
class AuthService {
  // Current session
  static const _kDriverId    = 'auth_driver_id';
  static const _kDriverName  = 'auth_driver_name';
  static const _kDriverEmail = 'auth_driver_email';
  static const _kToken       = 'auth_token';

  // Recent drivers list (last 3)
  static const _kRecentList  = 'auth_recent_drivers';
  static const _maxRecent    = 3;

  /// Save the current session AND add to recent drivers.
  static Future<void> saveLogin({
    required int driverId,
    required String driverName,
    required String driverEmail,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDriverId, driverId);
    await prefs.setString(_kDriverName, driverName);
    await prefs.setString(_kDriverEmail, driverEmail);
    await prefs.setString(_kToken, token);

    // Update recent list: this driver moves to the front.
    final recents = await getRecentDrivers();
    recents.removeWhere((d) => d.email == driverEmail);
    recents.insert(0, RecentDriver(name: driverName, email: driverEmail));
    while (recents.length > _maxRecent) {
      recents.removeLast();
    }
    await prefs.setString(_kRecentList,
        jsonEncode(recents.map((d) => d.toMap()).toList()));
  }

  static Future<int?> currentDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDriverId);
  }

  static Future<String?> currentDriverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDriverName);
  }

  static Future<bool> isLoggedIn() async {
    return (await currentDriverId()) != null;
  }

  /// Returns the last few drivers, newest first.
  static Future<List<RecentDriver>> getRecentDrivers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRecentList);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((m) => RecentDriver.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Wipe current session (but keep recent drivers list for quick switch).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDriverId);
    await prefs.remove(_kDriverName);
    await prefs.remove(_kDriverEmail);
    await prefs.remove(_kToken);
  }

  /// Wipe EVERYTHING including recents. Use for "forget this tablet".
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDriverId);
    await prefs.remove(_kDriverName);
    await prefs.remove(_kDriverEmail);
    await prefs.remove(_kToken);
    await prefs.remove(_kRecentList);
  }

  /// Remove one driver from recents (long-press chip → remove).
  static Future<void> removeRecent(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final recents = await getRecentDrivers();
    recents.removeWhere((d) => d.email == email);
    await prefs.setString(_kRecentList,
        jsonEncode(recents.map((d) => d.toMap()).toList()));
  }
}

/// Small value type for the recent-drivers list.
class RecentDriver {
  final String name;
  final String email;
  RecentDriver({required this.name, required this.email});

  Map<String, dynamic> toMap() => {'name': name, 'email': email};
  factory RecentDriver.fromMap(Map<String, dynamic> m) =>
      RecentDriver(name: m['name'] as String, email: m['email'] as String);

  /// Initials for the avatar: "Ali Driver" → "AD". Falls back to first 2 chars.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return email.isNotEmpty ? email.substring(0, 1).toUpperCase() : '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1)
                       .toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}
