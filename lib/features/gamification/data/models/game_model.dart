import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GameModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String type; // 'quiz', 'challenge', 'activity', 'mini_game'
  final int pointsReward;
  final Map<String, dynamic> gameData;
  final List<String> tags;
  final String difficulty; // 'easy', 'medium', 'hard'
  final Duration estimatedTime;
  final bool isMultiplayer;
  final String iconUrl;

  const GameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.pointsReward,
    required this.gameData,
    required this.tags,
    required this.difficulty,
    required this.estimatedTime,
    required this.isMultiplayer,
    required this.iconUrl,
  });

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      pointsReward: data['pointsReward'] ?? 0,
      gameData: Map<String, dynamic>.from(data['gameData'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
      difficulty: data['difficulty'] ?? 'easy',
      estimatedTime: Duration(minutes: data['estimatedTimeMinutes'] ?? 5),
      isMultiplayer: data['isMultiplayer'] ?? false,
      iconUrl: data['iconUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'pointsReward': pointsReward,
      'gameData': gameData,
      'tags': tags,
      'difficulty': difficulty,
      'estimatedTimeMinutes': estimatedTime.inMinutes,
      'isMultiplayer': isMultiplayer,
      'iconUrl': iconUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        pointsReward,
        gameData,
        tags,
        difficulty,
        estimatedTime,
        isMultiplayer,
        iconUrl,
      ];
}

class GameSessionModel extends Equatable {
  final String id;
  final String gameId;
  final String relationshipId;
  final List<String> playerIds;
  final Map<String, int> scores;
  final String status; // 'waiting', 'in_progress', 'completed', 'abandoned'
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic> sessionData;
  final int pointsAwarded;

  const GameSessionModel({
    required this.id,
    required this.gameId,
    required this.relationshipId,
    required this.playerIds,
    required this.scores,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.sessionData,
    required this.pointsAwarded,
  });

  factory GameSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameSessionModel(
      id: doc.id,
      gameId: data['gameId'] ?? '',
      relationshipId: data['relationshipId'] ?? '',
      playerIds: List<String>.from(data['playerIds'] ?? []),
      scores: Map<String, int>.from(data['scores'] ?? {}),
      status: data['status'] ?? 'waiting',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      sessionData: Map<String, dynamic>.from(data['sessionData'] ?? {}),
      pointsAwarded: data['pointsAwarded'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gameId': gameId,
      'relationshipId': relationshipId,
      'playerIds': playerIds,
      'scores': scores,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'sessionData': sessionData,
      'pointsAwarded': pointsAwarded,
    };
  }

  @override
  List<Object?> get props => [
        id,
        gameId,
        relationshipId,
        playerIds,
        scores,
        status,
        createdAt,
        completedAt,
        sessionData,
        pointsAwarded,
      ];
}

class RelationshipPointsModel extends Equatable {
  final String id;
  final String relationshipId;
  final int totalPoints;
  final int weeklyPoints;
  final int monthlyPoints;
  final Map<String, int> categoryPoints; // 'communication', 'activities', 'games', 'milestones'
  final List<PointTransaction> recentTransactions;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivity;
  final Map<String, dynamic> achievements;

  const RelationshipPointsModel({
    required this.id,
    required this.relationshipId,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.categoryPoints,
    required this.recentTransactions,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivity,
    required this.achievements,
  });

  factory RelationshipPointsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RelationshipPointsModel(
      id: doc.id,
      relationshipId: data['relationshipId'] ?? '',
      totalPoints: data['totalPoints'] ?? 0,
      weeklyPoints: data['weeklyPoints'] ?? 0,
      monthlyPoints: data['monthlyPoints'] ?? 0,
      categoryPoints: Map<String, int>.from(data['categoryPoints'] ?? {}),
      recentTransactions: (data['recentTransactions'] as List<dynamic>? ?? [])
          .map((t) => PointTransaction.fromMap(t as Map<String, dynamic>))
          .toList(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActivity: (data['lastActivity'] as Timestamp).toDate(),
      achievements: Map<String, dynamic>.from(data['achievements'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'relationshipId': relationshipId,
      'totalPoints': totalPoints,
      'weeklyPoints': weeklyPoints,
      'monthlyPoints': monthlyPoints,
      'categoryPoints': categoryPoints,
      'recentTransactions': recentTransactions.map((t) => t.toMap()).toList(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'achievements': achievements,
    };
  }

  @override
  List<Object?> get props => [
        id,
        relationshipId,
        totalPoints,
        weeklyPoints,
        monthlyPoints,
        categoryPoints,
        recentTransactions,
        currentStreak,
        longestStreak,
        lastActivity,
        achievements,
      ];
}

class PointTransaction extends Equatable {
  final String id;
  final int points;
  final String reason;
  final String category;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PointTransaction({
    required this.id,
    required this.points,
    required this.reason,
    required this.category,
    required this.timestamp,
    required this.metadata,
  });

  factory PointTransaction.fromMap(Map<String, dynamic> map) {
    return PointTransaction(
      id: map['id'] ?? '',
      points: map['points'] ?? 0,
      reason: map['reason'] ?? '',
      category: map['category'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points,
      'reason': reason,
      'category': category,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [id, points, reason, category, timestamp, metadata];
}

class LeaderboardEntry extends Equatable {
  final String relationshipId;
  final String coupleNames;
  final int totalPoints;
  final int rank;
  final String avatarUrl;
  final Map<String, dynamic> stats;

  const LeaderboardEntry({
    required this.relationshipId,
    required this.coupleNames,
    required this.totalPoints,
    required this.rank,
    required this.avatarUrl,
    required this.stats,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      relationshipId: map['relationshipId'] ?? '',
      coupleNames: map['coupleNames'] ?? '',
      totalPoints: map['totalPoints'] ?? 0,
      rank: map['rank'] ?? 0,
      avatarUrl: map['avatarUrl'] ?? '',
      stats: Map<String, dynamic>.from(map['stats'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [relationshipId, coupleNames, totalPoints, rank, avatarUrl, stats];
}
