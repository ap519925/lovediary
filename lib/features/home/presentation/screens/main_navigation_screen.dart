import 'package:flutter/material.dart';
import 'package:lovediary/features/chat/presentation/screens/chat_screen.dart';
import 'package:lovediary/features/home/presentation/screens/dashboard_screen.dart';
import 'package:lovediary/features/map/presentation/screens/map_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/profile_screen.dart';
import 'package:lovediary/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_event.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lovediary/features/map/presentation/bloc/map_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MainNavigationScreen extends StatefulWidget {
  final String partner1Name;
  final String partner2Name;
  final DateTime anniversaryDate;
  final double distanceApart;
  final DateTime nextMeetingDate;
  final String userId;

  const MainNavigationScreen({
    super.key,
    required this.partner1Name,
    required this.partner2Name,
    required this.anniversaryDate,
    required this.distanceApart,
    required this.nextMeetingDate,
    required this.userId,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProfileBloc(
            firestore: FirebaseFirestore.instance,
            storage: FirebaseStorage.instance,
            auth: FirebaseAuth.instance,
          ),
        ),
      ],
      child: WillPopScope(
        onWillPop: () async {
          final currentNavigator = _navigatorKeys[_selectedIndex];
          if (currentNavigator.currentState?.canPop() ?? false) {
            currentNavigator.currentState?.pop();
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Love Diary'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              Navigator(
                key: _navigatorKeys[0],
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => DashboardScreen(
                    partner1Name: widget.partner1Name,
                    partner2Name: widget.partner2Name,
                    anniversaryDate: widget.anniversaryDate,
                    distanceApart: widget.distanceApart,
                    nextMeetingDate: widget.nextMeetingDate,
                  ),
                ),
              ),
              Navigator(
                key: _navigatorKeys[1],
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => const ChatScreen(),
                ),
              ),
              Navigator(
                key: _navigatorKeys[2],
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => const CalendarScreen(),
                ),
              ),
              Navigator(
                key: _navigatorKeys[3],
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => MapBloc(
                      firestore: FirebaseFirestore.instance,
                      userId: widget.userId,
                      partnerId: 'PARTNER_ID', // Replace with actual partner ID
                    ),
                    child: const MapScreen(),
                  ),
                ),
              ),
              Navigator(
                key: _navigatorKeys[4],
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: widget.userId),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Calendar',
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
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.pink,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
