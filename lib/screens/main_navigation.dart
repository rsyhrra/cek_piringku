import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _onNavigateToHistory() {
    setState(() {
      _currentIndex = 2; // Index of HistoryScreen
    });
  }

  void _onScanPressed() {
    setState(() {
      _currentIndex = 1; // Index of ScanScreen
    });
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onScanPressed: _onScanPressed),
      ScanScreen(onViewHistory: _onNavigateToHistory),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'BERANDA'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), label: 'SCAN'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'RIWAYAT'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'PROFIL'),
        ],
      ),
    );
  }
}
