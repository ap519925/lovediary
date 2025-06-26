import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_event.dart';
import 'package:lovediary/features/auth/presentation/screens/login_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/register_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/partner_link_screen.dart';
import 'package:lovediary/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:lovediary/features/chat/presentation/screens/chat_screen.dart';
import 'package:lovediary/features/home/presentation/screens/home_screen.dart';
import 'package:lovediary/features/map/presentation/screens/map_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/partner_search_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  static const routeName = '/dashboard';
  final String partner1Name;
  final String partner2Name;
  final DateTime anniversaryDate;
  final double distanceApart;
  final DateTime nextMeetingDate;
  final String? birthday;
  final String? location;

  const DashboardScreen({
    super.key,
    required this.partner1Name,
    required this.partner2Name,
    required this.anniversaryDate,
    required this.distanceApart,
    required this.nextMeetingDate,
    this.birthday,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome to your Love Diary Dashboard',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Navigation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildNavigationItem(
                            context,
                            'Home',
                            Icons.home,
                            () => Navigator.pushNamed(context, HomeScreen.routeName),
                          ),
                          _buildNavigationItem(
                            context,
                            'Calendar',
                            Icons.calendar_today,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CalendarScreen()),
                            ),
                          ),
                          _buildNavigationItem(
                            context,
                            'Chat',
                            Icons.chat,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChatScreen()),
                            ),
                          ),
                          _buildNavigationItem(
                            context,
                            'Map',
                            Icons.map,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MapScreen()),
                            ),
                          ),
                          _buildNavigationItem(
                            context,
                            'Profile',
                            Icons.person,
                            () => Navigator.pushNamed(context, ProfileScreen.routeName),
                          ),
                          _buildNavigationItem(
                            context,
                            'Partner Search',
                            Icons.search,
                            () => Navigator.pushNamed(context, PartnerSearchScreen.routeName),
                          ),
                          _buildNavigationItem(
                            context,
                            'Partner Link',
                            Icons.link,
                            () => Navigator.pushNamed(context, PartnerLinkScreen.routeName),
                          ),
                          _buildNavigationItem(
                            context,
                            'Login',
                            Icons.login,
                            () => Navigator.pushNamed(context, LoginScreen.routeName),
                          ),
                          _buildNavigationItem(
                            context,
                            'Register',
                            Icons.app_registration,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Relationship info card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relationship Info',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Partners', '$partner1Name & $partner2Name'),
                      _buildInfoRow('Anniversary', _formatDate(anniversaryDate)),
                      _buildInfoRow('Distance Apart', '${distanceApart.toStringAsFixed(0)} km'),
                      _buildInfoRow('Next Meeting', _formatDate(nextMeetingDate)),
                      if (birthday != null && birthday!.isNotEmpty)
                        _buildInfoRow('Birthday', birthday!),
                      if (location != null && location!.isNotEmpty)
                        _buildInfoRow('Location', location!),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
