import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovediary/features/home/presentation/screens/dashboard_screen.dart';
import 'package:lovediary/features/map/presentation/screens/map_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  static const routeName = '/main';
  final Map<String, dynamic> userData;

  const MainNavigationScreen({super.key, required this.userData});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(
      partner1Name: widget.userData['partner1Name'] ?? 'Partner 1',
      partner2Name: widget.userData['partner2Name'] ?? 'Partner 2',
      anniversaryDate: widget.userData['anniversaryDate'] ?? DateTime.now(),
      distanceApart: widget.userData['distanceApart'] ?? 0.0,
      nextMeetingDate: widget.userData['nextMeetingDate'] ?? DateTime.now(),
      partner1Image: widget.userData['partner1Image'],
      partner2Image: widget.userData['partner2Image'],
    ),
    const MapScreen(),
    ProfileScreen(
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
