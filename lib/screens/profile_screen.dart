import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'leave_screen.dart';
import 'login_screen.dart';

/// ProfileScreen — driver info + actions menu + logout button.
///
/// Profile data (phone number etc.) is fetched from the backend on load
/// via GET /api/driver/profile/{id}. Refreshed every time the user opens
/// Profile or pulls down to refresh.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db   = DatabaseHelper.instance;
  final _sync = SyncService();
  final _api  = ApiService();

  int?    _driverId;
  String? _driverName;
  String? _driverPhone;       // ← NEW: fetched from API
  int     _unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final id   = await AuthService.currentDriverId();
    final name = await AuthService.currentDriverName();
    int unsynced = 0;
    String? phone;

    if (id != null) {
      final list = await _db.getUnsyncedByDriver(id);
      unsynced = list.length;

      // Fetch phone from server. Returns null gracefully on failure
      // (offline, 404, etc.) — we just won't show the phone field.
      final remote = await _api.fetchDriverProfile(id);
      phone = remote?['phone']?.toString();
    }

    if (mounted) {
      setState(() {
        _driverId      = id;
        _driverName    = name;
        _driverPhone   = phone;
        _unsyncedCount = unsynced;
      });
    }
  }

  Future<void> _openLeave() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaveScreen()),
    );
    if (mounted) _loadProfile();
  }

  Future<void> _logout() async {
    if (_driverId == null) return;

    final pending = await _db.getUnsyncedByDriver(_driverId!);

    if (pending.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Syncing before logout'),
          content: Row(
            children: const [
              SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 16),
              Expanded(child: Text('Pushing your unsynced trips…')),
            ],
          ),
        ),
      );

      final ok = await _sync.syncDriverOrFail(_driverId!);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (!ok) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cannot log out'),
            content: Text(
              '${pending.length} trip${pending.length==1?'':'s'} not yet synced. '
              'You must be online to log out so your work is not lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    await _db.clearForDriver(_driverId!);
    await AuthService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ----- Avatar + name + phone -----
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.indigo,
                    child: Text(
                      _initials(_driverName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _driverName ?? 'Loading…',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  // Phone number — only shown if we have one
                  if (_driverPhone != null && _driverPhone!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(_driverPhone!,
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ----- Sync status -----
            Card(
              child: ListTile(
                leading: Icon(
                  _unsyncedCount > 0 ? Icons.cloud_upload : Icons.cloud_done,
                  color: _unsyncedCount > 0 ? Colors.orange : Colors.green,
                ),
                title: Text(_unsyncedCount > 0
                    ? '$_unsyncedCount trip${_unsyncedCount==1?'':'s'} pending sync'
                    : 'All trips synced'),
                subtitle: Text(_unsyncedCount > 0
                    ? 'These will sync automatically when connected.'
                    : 'Safe to log out.'),
              ),
            ),

            const SizedBox(height: 24),

            // ----- Actions menu -----
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'REQUESTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.event_busy, color: Colors.orange.shade700),
                ),
                title: const Text('Leave Applications',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Apply for leave and view history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openLeave,
              ),
            ),

            const SizedBox(height: 32),

            // ----- Logout -----
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade800,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'Smart Bus Driver · v1.0',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
