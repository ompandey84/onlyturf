import 'package:flutter/material.dart';
import 'package:owner_application/features/dashboard/overview_tab.dart';
import 'package:owner_application/features/bookings/bookings_tab.dart';
import 'package:owner_application/features/facilities/facilities_tab.dart';
import 'package:owner_application/features/dashboard/profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const OverviewTab(),
    const BookingsTab(),
    const FacilitiesTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        shadowColor: Colors.black12,
        elevation: 10,
        indicatorColor: Theme.of(context).primaryColor.withOpacity(0.1),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(
              Icons.calendar_today,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: const Icon(Icons.stadium_outlined),
            selectedIcon: Icon(
              Icons.stadium,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Facilities',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
