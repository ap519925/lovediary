import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_event.dart';
import 'package:lovediary/features/home/presentation/screens/dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Love Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
          ),
        ],
      ),
      body: DashboardScreen(
        partner1Name: 'You',
        partner2Name: 'Partner',
        partner1Image: 'https://example.com/you.jpg',
        partner2Image: 'https://example.com/partner.jpg',
        anniversaryDate: DateTime(2023, 1, 1),
        distanceApart: 100.5,
        nextMeetingDate: DateTime.now().add(const Duration(days: 30)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Memories',
          ),
        ],
      ),
    );
  }
}
