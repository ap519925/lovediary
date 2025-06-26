import 'package:flutter/material.dart';
import 'package:lovediary/features/chat/presentation/screens/chat_screen.dart';
import 'package:lovediary/features/home/presentation/screens/dashboard_screen.dart';
import 'package:lovediary/features/map/presentation/screens/map_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/profile_screen.dart';
import 'package:lovediary/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_event.dart';
import 'package:lovediary/features/map/presentation/bloc/map_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovediary/l10n/app_localizations.dart';

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

  Future<String?> _getPartnerId(String userId) async {
    try {
      // Get the user document
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('User document not found');
        return null;
      }
      
      final userData = userDoc.data();
      
      // Check if the user has a partner field
      if (userData != null && userData.containsKey('partnerId')) {
        final partnerId = userData['partnerId'] as String?;
        print('Found partner ID: $partnerId');
        return partnerId;
      }
      
      // If no direct partner ID, check relationship collection
      final relationshipQuery = await FirebaseFirestore.instance
          .collection('relationships')
          .where('users', arrayContains: userId)
          .limit(1)
          .get();
      
      if (relationshipQuery.docs.isNotEmpty) {
        final relationshipData = relationshipQuery.docs.first.data();
        final users = relationshipData['users'] as List<dynamic>;
        
        // Find the other user in the relationship
        for (final user in users) {
          if (user != userId) {
            print('Found partner ID from relationship: $user');
            return user as String;
          }
        }
      }
      
      // User doesn't have a partner yet - this is normal for new users
      return null;
    } catch (e) {
      print('Error getting partner ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
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
            title: Text(AppLocalizations.of(context)?.appTitle ?? 'Love Diary'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                tooltip: AppLocalizations.of(context)?.settings ?? 'Settings',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
                tooltip: AppLocalizations.of(context)?.logout ?? 'Logout',
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
                  builder: (context) => FutureBuilder<String?>(
                    future: _getPartnerId(widget.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final partnerId = snapshot.data ?? '';
                      
                      return BlocProvider(
                        create: (context) => MapBloc(
                          firestore: FirebaseFirestore.instance,
                          userId: widget.userId,
                          partnerId: partnerId,
                        ),
                        child: const MapScreen(),
                      );
                    },
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
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: AppLocalizations.of(context)?.home ?? 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat),
                label: AppLocalizations.of(context)?.chat ?? 'Chat',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_today),
                label: AppLocalizations.of(context)?.calendar ?? 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.map),
                label: AppLocalizations.of(context)?.map ?? 'Map',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: AppLocalizations.of(context)?.profile ?? 'Profile',
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
    );
  }
}
