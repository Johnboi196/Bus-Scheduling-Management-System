import 'package:flutter/material.dart';
import 'trip_screen.dart';
import 'available_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

/// HomeShell — main container with bottom navigation.
///
/// Four tabs:
///   - Schedule  : today's trips with START/END actions
///   - Available : volunteer for unassigned trips
///   - History   : past completed trips with durations
///   - Profile   : driver info, leave applications, logout
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final _screens = const [
    TripScreen(),
    AvailableScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_task_outlined),
            selectedIcon: Icon(Icons.add_task),
            label: 'Available',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
