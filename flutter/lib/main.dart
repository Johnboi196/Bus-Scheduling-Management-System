import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() => runApp(const SmartBusApp());

class SmartBusApp extends StatelessWidget {
  const SmartBusApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bus Device',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const _RootGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Decides whether to show Login or HomeShell based on whether a
/// driver is already logged in. After login, the user always lands on
/// HomeShell which provides the bottom navigation.
class _RootGate extends StatelessWidget {
  const _RootGate();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (_, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Startup error:\n${snap.error}',
                         textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data! ? const HomeShell() : const LoginScreen();
      },
    );
  }
}
