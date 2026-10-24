import 'dart:async';
import 'package:application/core/theme/app_colors.dart';
import 'package:application/features/home/dashboard_screen.dart';
import 'package:application/features/home/home_tab.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCity = 'Indore';
  String _userGender = 'Male';
  StreamSubscription<AuthState>? _authSubscription;

  void _onCityChanged(String city) {
    setState(() {
      _selectedCity = city;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserCity();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (mounted) {
        _loadUserCity();
        setState(() {});
      }
    });
  }

  Future<void> _loadUserCity() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('city, gender')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null && mounted) {
        setState(() {
          if (profile['city'] != null) _selectedCity = profile['city'];
          if (profile['gender'] != null) _userGender = profile['gender'];
        });
      }
    } catch (_) {
      // Fallback: keep default
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _pages => [
    HomeTab(
      selectedCity: _selectedCity,
      userGender: _userGender,
      onCityChanged: (city) => _onCityChanged(city),
    ),
    DashboardScreen(isActiveTab: _selectedIndex == 1),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, Icons.home, 'Home', 0),
                _buildNavItem(
                  Icons.confirmation_number_rounded,
                  Icons.confirmation_number,
                  'Bookings',
                  1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSec(context),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSec(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
