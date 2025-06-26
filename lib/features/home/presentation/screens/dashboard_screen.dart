import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lovediary/features/auth/presentation/screens/login_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/partner_link_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/register_screen.dart';
import 'package:lovediary/features/home/presentation/screens/home_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/partner_search_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  static const routeName = '/dashboard';

  void _navigateToScreen(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  Widget _buildDrawerItem(IconData icon, String label, String routeName, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      onTap: () => _navigateToScreen(context, routeName),
    );
  }

  // Helper methods moved inside the class
  Widget _buildProfileCard(String name, String? imageUrl, BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'profile-$name',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: imageUrl == null 
                  ? Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required List<Widget> children,
    required BuildContext context,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  final String partner1Name;
  final String partner2Name;
  final String? partner1Image;
  final String? partner2Image;
  final DateTime anniversaryDate;
  final double distanceApart;
  final DateTime nextMeetingDate;
  final String? birthday;
  final String? location;

  const DashboardScreen({
    super.key,
    required this.partner1Name,
    required this.partner2Name,
    this.partner1Image,
    this.partner2Image,
    required this.anniversaryDate,
    required this.distanceApart,
    required this.nextMeetingDate,
    this.birthday,
    this.location,
  });

  int get daysTogether {
    return DateTime.now().difference(anniversaryDate).inDays;
  }

  int get daysUntilMeeting {
    return nextMeetingDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Love Diary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.home, 'Home', HomeScreen.routeName, context),
            _buildDrawerItem(Icons.person, 'Profile', ProfileScreen.routeName, context),
            _buildDrawerItem(Icons.search, 'Partner Search', PartnerSearchScreen.routeName, context),
            _buildDrawerItem(Icons.link, 'Partner Link', PartnerLinkScreen.routeName, context),
            _buildDrawerItem(Icons.login, 'Login', LoginScreen.routeName, context),
            _buildDrawerItem(Icons.person_add, 'Register', RegisterScreen.routeName, context),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Couple Profile Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileCard(partner1Name, partner1Image, context),
                _buildProfileCard(partner2Name, partner2Image, context),
              ],
            ),
            const SizedBox(height: 32),
            
            // Stats Section
            _buildStatCard(
              title: 'Relationship Stats',
              children: [
                _buildStatItem('Days Together', '$daysTogether days', context),
                _buildStatItem('Anniversary Date', 
                  DateFormat('MMMM d, y').format(anniversaryDate), context),
                _buildStatItem('Current Distance', 
                  '${distanceApart.toStringAsFixed(1)} km apart', context),
                _buildStatItem('Next Meeting', 
                  '$daysUntilMeeting days (${DateFormat('MMMM d').format(nextMeetingDate)})', context),
                if (birthday != null && birthday!.isNotEmpty)
                  _buildStatItem('Birthday', birthday!, context),
                if (location != null && location!.isNotEmpty)
                  _buildStatItem('Location', location!, context),
              ],
              context: context,
            ),
          ],
        ),
      ),
    );
  }

}
