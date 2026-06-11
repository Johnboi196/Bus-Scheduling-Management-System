import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _passFocus = FocusNode();
  final _api = ApiService();

  List<RecentDriver> _recents = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final list = await AuthService.getRecentDrivers();
    setState(() => _recents = list);
    // If no recents yet (first launch ever), prefill the demo account
    // so testers can try the app without typing.
    if (_recents.isEmpty) {
      _email.text = 'nazir@maraliner.com';
      _pass.text  = 'password123';
    }
  }

  /// User tapped a recent-driver chip.
  void _pickRecent(RecentDriver d) {
    setState(() {
      _email.text = d.email;
      _pass.text  = '';
      _error      = null;
    });
    // Focus the password field so the keyboard pops up.
    _passFocus.requestFocus();
  }

  /// User long-pressed a chip → option to remove from recents.
  Future<void> _removeRecent(RecentDriver d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${d.name}?'),
        content: const Text('This will only remove the quick-select chip. '
                            'The driver account itself is not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.removeRecent(d.email);
      _loadRecents();
    }
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _api.login(
        email: _email.text.trim(),
        password: _pass.text,
        role: 'driver',
      );

      final user  = result['user'] as Map<String, dynamic>;
      final token = result['sessionToken']?.toString() ?? '';

      await AuthService.saveLogin(
        driverId:    user['driver_id'] is int
                        ? user['driver_id'] as int
                        : int.parse(user['driver_id'].toString()),
        driverName:  user['full_name']?.toString() ?? '',
        driverEmail: user['email']?.toString() ?? '',
        token:       token,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
   title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text('Driver Login'),
      Image.asset(
        'assets/images/logo.png',
        height: 28,
        fit: BoxFit.contain,
                 ),
              ],
            ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----- Quick-switch chips (only if we have recents) -----
              if (_recents.isNotEmpty) ...[
                const Text('Recent drivers',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _recents.map(_buildChip).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or sign in with email',
                          style: TextStyle(color: Colors.grey.shade600,
                                           fontSize: 12)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ----- Email / password form -----
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                focusNode: _passFocus,
                obscureText: true,
                onSubmitted: (_) => _login(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: TextStyle(color: Colors.red.shade700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _busy ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _busy
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('LOG IN', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One recent-driver chip with circular avatar of initials.
  Widget _buildChip(RecentDriver d) {
    // Give each driver a stable colour based on the hash of their email,
    // so Ali is always indigo, Siti is always green, etc.
    final colours = [
      Colors.indigo, Colors.teal, Colors.deepOrange,
      Colors.purple, Colors.cyan, Colors.brown,
    ];
    final colour = colours[d.email.hashCode.abs() % colours.length];

    return InkWell(
      onTap: _busy ? null : () => _pickRecent(d),
      onLongPress: _busy ? null : () => _removeRecent(d),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colour,
              child: Text(d.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(d.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(d.email,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
