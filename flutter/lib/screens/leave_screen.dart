import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// LeaveScreen — driver can submit a leave application and see their history.
///
/// Maps to Use Case Diagram: "Manage leave applications" (driver side).
/// Backend route: POST /api/leave/apply (already exists in LeaveController).
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  int? _driverId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final id = await AuthService.currentDriverId();
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    _driverId = id;

    try {
      // GET /api/leave/byDriver/{id} — uses the new endpoint we'll add
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/leave/byDriver/$id'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['leaves'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          _history = list;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Leave history error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _openApplyDialog() async {
    DateTime? startDate;
    DateTime? endDate;
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Apply for Leave'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ----- Start date picker -----
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Start date'),
                  subtitle: Text(startDate == null
                      ? 'Tap to select'
                      : _fmtDate(startDate!)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setLocal(() => startDate = picked);
                  },
                ),
                // ----- End date picker -----
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('End date'),
                  subtitle: Text(endDate == null
                      ? 'Tap to select'
                      : _fmtDate(endDate!)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: endDate ?? startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setLocal(() => endDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Family event, medical, vacation…',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please pick both dates.')),
                  );
                  return;
                }
                if (endDate!.isBefore(startDate!)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('End date cannot be before start.')),
                  );
                  return;
                }
                final ok = await _submit(startDate!, endDate!, reasonCtrl.text);
                if (ok && mounted) {
                  Navigator.pop(ctx);
                  _loadHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Leave application submitted.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _submit(DateTime start, DateTime end, String reason) async {
    if (_driverId == null) return false;
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/leave/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driver_id':  _driverId,
          'start_date': _fmtDate(start),
          'end_date':   _fmtDate(end),
          'reason':     reason.trim(),
        }),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Submit leave error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: _history.isEmpty
                  ? ListView(
                      // ListView keeps RefreshIndicator working even when empty
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No leave applications yet.',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (_, i) => _buildRow(_history[i]),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApplyDialog,
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> row) {
    final status = row['status']?.toString() ?? 'Pending';
    final start  = row['start_date']?.toString() ?? '';
    final end    = row['end_date']?.toString() ?? '';
    final reason = row['reason']?.toString() ?? '';

    final colour = switch (status) {
      'Approved' => Colors.green,
      'Rejected' => Colors.red,
      _          => Colors.orange,
    };
    final icon = switch (status) {
      'Approved' => Icons.check_circle,
      'Rejected' => Icons.cancel,
      _          => Icons.hourglass_top,
    };

    // Calculate number of days
    int days = 0;
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      days = e.difference(s).inDays + 1;
    } catch (_) {}

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colour.withValues(alpha: 0.15),
        child: Icon(icon, color: colour),
      ),
      title: Text('$start  →  $end',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$days day${days==1?'':'s'}'),
          if (reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(reason,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(color: colour, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      isThreeLine: reason.isNotEmpty,
    );
  }
}
