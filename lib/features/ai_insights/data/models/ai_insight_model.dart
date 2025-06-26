import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AIInsightModel extends Equatable {
  final String id;
  final String relationshipId;
  final String type; // 'mood_analysis', 'memory_lane', 'date_suggestion', 'conflict_resolution'
  final String title;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final bool isRead;
  final double confidence;

  const AIInsightModel({
    required this.id,
    required this.relationshipId,
    required this.type,
    required this.title,
    required this.content,
    required this.metadata,
    required this.createdAt,
    required this.isRead,
    required this.confidence,
  });

  factory AIInsightModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIInsightModel(
      id: doc.id,
      relationshipId: data['relationshipId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      confidence: (data['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'relationshipId': relationshipId,
      'type': type,
      'title': title,
      'content': content,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'confidence': confidence,
    };
  }

  AIInsightModel copyWith({
    String? id,
    String? relationshipId,
    String? type,
    String? title,
    String? content,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? isRead,
    double? confidence,
  }) {
    return AIInsightModel(
      id: id ?? this.id,
      relationshipId: relationshipId ?? this.relationshipId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props => [
        id,
        relationshipId,
        type,
        title,
        content,
        metadata,
        createdAt,
        isRead,
        confidence,
      ];
}

class MemoryLaneModel extends Equatable {
  final String id;
  final String relationshipId;
  final String title;
  final String description;
  final List<String> photoUrls;
  final List<String> messageIds;
  final DateTime originalDate;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const MemoryLaneModel({
    required this.id,
    required this.relationshipId,
    required this.title,
    required this.description,
    required this.photoUrls,
    required this.messageIds,
    required this.originalDate,
    required this.createdAt,
    required this.metadata,
  });

  factory MemoryLaneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemoryLaneModel(
      id: doc.id,
      relationshipId: data['relationshipId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      messageIds: List<String>.from(data['messageIds'] ?? []),
      originalDate: (data['originalDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'relationshipId': relationshipId,
      'title': title,
      'description': description,
      'photoUrls': photoUrls,
      'messageIds': messageIds,
      'originalDate': Timestamp.fromDate(originalDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        relationshipId,
        title,
        description,
        photoUrls,
        messageIds,
        originalDate,
        createdAt,
        metadata,
      ];
}
