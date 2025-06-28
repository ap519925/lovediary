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
import 'package:lovediary/features/map/presentation/bloc/map_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovediary/l10n/app_localizations.dart';
import 'package:lovediary/core/services/partner_service.dart';

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
  
  late final PartnerService _partnerService;
  
  @override
  void initState() {
    super.initState();
    _partnerService = PartnerService();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) return;
          
          final currentNavigator = _navigatorKeys[_selectedIndex];
          if (currentNavigator.currentState?.canPop() ?? false) {
            currentNavigator.currentState?.pop();
          } else {
            // Allow the app to close if we're at the root of all navigators
            Navigator.of(context).pop();
          }
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
                  builder: (context) => CalendarScreen(
                    userId: widget.userId,
                  ),
                ),
              ),
              Navigator(
                key: _navigatorKeys[3],
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => FutureBuilder<String?>(
                    future: _partnerService.getPartnerId(widget.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading map: ${snapshot.error}'));
                      }
                      
                      final partnerId = snapshot.data ?? '';
                      
                      // Create MapBloc once and update partnerId when available
                      final mapBloc = BlocProvider.of<MapBloc>(context);
                      mapBloc.add(UpdatePartnerId(partnerId));
                      return const MapScreen();
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
