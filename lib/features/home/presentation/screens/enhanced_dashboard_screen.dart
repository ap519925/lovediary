import 'package:flutter/material.dart';
import 'package:lovediary/features/relationship/data/models/relationship_model.dart';
import 'package:lovediary/features/gamification/data/models/game_model.dart';
import 'dart:math';
import 'package:lovediary/features/translation/data/translation_service.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showCelebration = false;
  
  // Mock data - replace with actual BLoC data
  final RelationshipModel _mockRelationship = RelationshipModel(
    id: '1',
    user1Id: 'user1',
    user2Id: 'user2',
    anniversaryDate: DateTime.now().subtract(const Duration(days: 365)),
    status: 'active',
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );

  final RelationshipPointsModel _mockPoints = RelationshipPointsModel(
    id: '1',
    relationshipId: '1',
    totalPoints: 2450,
    weeklyPoints: 180,
    monthlyPoints: 720,
    categoryPoints: {
      'communication': 800,
      'activities': 650,
      'games': 500,
      'milestones': 500,
    },
    recentTransactions: [],
    currentStreak: 7,
    longestStreak: 21,
    lastActivity: DateTime.now(),
    achievements: {
      'first_week': true,
      'communication_master': true,
      'game_champion': false,
    },
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerCelebration() {
    setState(() {
      _showCelebration = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCelebration = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildRelationshipStats(),
                    const SizedBox(height: 16),
                    _buildPointsOverview(),
                    const SizedBox(height: 16),
                    _buildAIInsights(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildMemoryLane(),
                    const SizedBox(height: 16),
                    _buildMiniGames(),
                    const SizedBox(height: 16),
                    _buildTranslationWidget(),
                  ]),
                ),
              ),
            ],
          ),
          if (_showCelebration)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CelebrationPainter(
                        progress: _animationController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Love Diary'),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink,
                Colors.purple,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.favorite,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // Show notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Navigate to settings
          },
        ),
      ],
    );
  }

  Widget _buildRelationshipStats() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Relationship Stats',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Days Together',
                  '${_mockRelationship.daysTogether}',
                  Icons.calendar_today,
                  Colors.pink,
                ),
                _buildStatItem(
                  'Current Streak',
                  '${_mockPoints.currentStreak}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Total Points',
                  '${_mockPoints.totalPoints}',
                  Icons.star,
                  Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPointsOverview() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Relationship Points',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _triggerCelebration(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.pink],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_mockPoints.totalPoints} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._mockPoints.categoryPoints.entries.map((entry) {
              final percentage = entry.value / _mockPoints.totalPoints;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key.toUpperCase()),
                        Text('${entry.value} pts'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'communication':
        return Colors.blue;
      case 'activities':
        return Colors.green;
      case 'games':
        return Colors.purple;
      case 'milestones':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAIInsights() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💝 Today\'s Insight',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your communication patterns show increased positivity this week! Consider planning a virtual date to celebrate.',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to AI insights
                    },
                    child: const Text('View All Insights'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  'Send Message',
                  Icons.message,
                  Colors.blue,
                  () {
                    // Navigate to chat
                  },
                ),
                _buildActionButton(
                  'Video Call',
                  Icons.video_call,
                  Colors.green,
                  () {
                    // Start video call
                  },
                ),
                _buildActionButton(
                  'Share Photo',
                  Icons.photo_camera,
                  Colors.orange,
                  () {
                    // Open camera
                  },
                ),
                _buildActionButton(
                  'Plan Date',
                  Icons.event,
                  Colors.purple,
                  () {
                    // Open calendar
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryLane() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_album, color: Colors.pink),
                const SizedBox(width: 8),
                Text(
                  'Memory Lane',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${index + 1} year ago',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniGames() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.games, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Mini Games',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGameCard(
                    'Love Quiz',
                    'Test how well you know each other',
                    Icons.quiz,
                    Colors.purple,
                    50,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGameCard(
                    'Photo Challenge',
                    'Complete daily photo missions',
                    Icons.camera_alt,
                    Colors.orange,
                    30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    String title,
    String description,
    IconData icon,
    Color color,
    int points,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$points pts',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Start game
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(60, 30),
                ),
                child: const Text(
                  'Play',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationWidget() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.translate, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Live Translation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message to translate...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Demo translation
                            const text = 'I love you';
                            final translated = await TranslationService.translateToChineseSimplified(text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Translation: $translated')),
                            );
                          },
                          icon: const Icon(Icons.translate),
                          label: const Text('EN → 中文'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Demo translation
                            const text = '我爱你';
                            final translated = await TranslationService.translateToEnglish(text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Translation: $translated')),
                            );
                          },
                          icon: const Icon(Icons.translate),
                          label: const Text('中文 → EN'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CelebrationPainter extends CustomPainter {
  final double progress;

  CelebrationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pink
      ..style = PaintingStyle.fill;

    final random = Random();
    final particleCount = 50;

    for (var i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = size.height * (1 - progress) + random.nextDouble() * 50;
      final radius = 2.0 + random.nextDouble() * 5.0;
      
      // Alternate colors
      if (i % 3 == 0) {
        paint.color = Colors.pink;
      } else if (i % 3 == 1) {
        paint.color = Colors.purple;
      } else {
        paint.color = Colors.orange;
      }
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CelebrationPainter oldDelegate) => true;
}
