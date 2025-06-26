import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RelationshipModel extends Equatable {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime anniversaryDate;
  final String status; // 'pending', 'active', 'ended'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const RelationshipModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.anniversaryDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory RelationshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RelationshipModel(
      id: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      anniversaryDate: (data['anniversaryDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'anniversaryDate': Timestamp.fromDate(anniversaryDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  int get daysTogether {
    return DateTime.now().difference(anniversaryDate).inDays;
  }

  RelationshipModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? anniversaryDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RelationshipModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        user1Id,
        user2Id,
        anniversaryDate,
        status,
        createdAt,
        updatedAt,
        metadata,
      ];
}
