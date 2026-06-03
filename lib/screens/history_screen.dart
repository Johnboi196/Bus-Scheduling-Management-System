import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// HistoryScreen — driver's completed trip history.
///
/// Lists every Completed trip for the logged-in driver, with the
/// computed duration in human-readable format. Includes a header
/// summary card showing total trips and total time worked.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _trips = [];
  int    _totalSeconds = 0;
  int    _totalTrips   = 0;
  int?   _driverId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Defensive integer parse that handles num, String, and null.
  /// Needed because PHP/MySQLi often returns numbers as strings in JSON.
  static int _asInt(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? def;
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

    final result = await _api.fetchTripHistory(id);
    if (result == null) {
      setState(() {
        _error = 'Could not load history. Pull down to retry.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _trips        = (result['trips'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _totalTrips   = _asInt(result['count']);
      _totalSeconds = _asInt(result['total_seconds']);
      _loading      = false;
    });
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    final parts = <String>[];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    if (s > 0 || parts.isEmpty) parts.add('${s}s');
    return parts.join(' ');
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} '
             '${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _timeOnly(String? ts) {
    if (ts == null) return '';
    final parts = ts.split(' ');
    return parts.length > 1 ? parts[1] : ts;
  }

  List<Object> _grouped() {
    final out = <Object>[];
    String? currentDate;
    for (final t in _trips) {
      final d = t['schedule_date']?.toString() ?? '';
      if (d != currentDate) {
        out.add(d);
        currentDate = d;
      }
      out.add(t);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
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
                  : _buildList(),
    );
  }

  Widget _buildList() {
    final grouped = _grouped();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: grouped.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _buildSummary();
          final item = grouped[i - 1];

          if (item is String) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _formatDate(item),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }
          return _buildTripCard(item as Map<String, dynamic>);
        },
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.list_alt,
                          color: Colors.indigo.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Total trips',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalTrips',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1, height: 40, color: Colors.indigo.shade100,
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer,
                          color: Colors.indigo.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Total time worked',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_totalSeconds),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> t) {
    // Use the defensive parser instead of `as num?` cast.
    final duration = _asInt(t['duration_seconds']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: route + plate
            Row(
              children: [
                Icon(Icons.directions_bus,
                    size: 20, color: Colors.indigo.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${t['route_name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 12, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${t['origin']} → ${t['destination']}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Bus ${t['plate_number']}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTimeBox(
                    label: 'Started',
                    value: _timeOnly(t['actual_start']?.toString()),
                  ),
                ),
                Container(
                  width: 1, height: 36, color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildTimeBox(
                    label: 'Ended',
                    value: _timeOnly(t['actual_end']?.toString()),
                  ),
                ),
                Container(
                  width: 1, height: 36, color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildTimeBox(
                    label: 'Duration',
                    value: _formatDuration(duration),
                    highlight: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? Colors.indigo.shade700 : Colors.black87,
            ),
          ),
        ],
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
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 8),
                Text('No completed trips yet.',
                    style: TextStyle(color: Colors.grey)),
                Text('Finish a trip on the Schedule tab to see it here.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
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
            Icon(Icons.error_outline,
                size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
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
}
