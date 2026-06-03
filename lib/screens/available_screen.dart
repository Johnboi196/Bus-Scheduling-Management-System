import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// AvailableScreen — list of unassigned trips any driver can volunteer for.
///
/// Any driver can submit a volunteer request, regardless of leave status.
/// The backend still filters out trips that overlap with the driver's
/// existing assignments, so they can't double-book themselves.
class AvailableScreen extends StatefulWidget {
  const AvailableScreen({super.key});
  @override
  State<AvailableScreen> createState() => _AvailableScreenState();
}

class _AvailableScreenState extends State<AvailableScreen> {
  final _api = ApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _trips = [];
  int? _driverId;

  /// Defensive int parser. PHP/MySQLi sometimes returns numbers as
  /// strings in JSON, and Dart's `as int` cast fails on those.
  static int _asInt(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? def;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final id = await AuthService.currentDriverId();
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    _driverId = id;
    try {
      final result = await _api.fetchAvailableTrips(id);
      setState(() {
        _trips   = (result['trips'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _volunteer(Map<String, dynamic> trip) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Volunteer to cover'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${trip['route_name']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${trip['origin']} → ${trip['destination']}'),
            const SizedBox(height: 4),
            Text(
              '${trip['schedule_date']} · ${trip['expected_start']} – ${trip['expected_end']}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note to supervisor (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true || _driverId == null) return;

    try {
      await _api.volunteerForTrip(
        scheduleId: _asInt(trip['schedule_id']),
        driverId:   _driverId!,
        note:       noteCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Volunteer request submitted. Awaiting supervisor approval.'),
          backgroundColor: Colors.green,
        ),
      );
      _load();   // refresh list — already_requested chip should appear
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _trips.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _trips.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (_, i) => _buildRow(_trips[i]),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 8),
                Text('No unassigned trips right now.',
                    style: TextStyle(color: Colors.grey)),
                Text('Pull down to refresh.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> t) {
    final alreadyRequested = (t['already_requested'] ?? 0) == 1
        || (t['already_requested'] ?? 0) == true;

    return ListTile(
      isThreeLine: true,
      leading: CircleAvatar(
        backgroundColor: Colors.indigo.shade50,
        child: Icon(Icons.directions_bus, color: Colors.indigo.shade700),
      ),
      title: Text('${t['route_name']}  •  ${t['plate_number']}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${t['origin']} → ${t['destination']}\n'
        '${t['schedule_date']}  ·  ${t['expected_start']} – ${t['expected_end']}',
      ),
      trailing: alreadyRequested
          ? const Chip(
              avatar: Icon(Icons.hourglass_top, size: 16, color: Colors.orange),
              label: Text('Pending', style: TextStyle(fontSize: 12)),
            )
          : ElevatedButton(
              onPressed: () => _volunteer(t),
              child: const Text('VOLUNTEER'),
            ),
    );
  }
}
