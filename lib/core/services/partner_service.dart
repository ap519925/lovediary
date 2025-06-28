import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovediary/core/utils/logger.dart';

/// Service for managing partner relationships efficiently
class PartnerService {
  static const String _tag = 'PartnerService';
  final FirebaseFirestore _firestore;
  
  // Cache for partner IDs to avoid repeated queries
  static final Map<String, String?> _partnerCache = {};
  
  PartnerService({FirebaseFirestore? firestore}) 
    : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Get partner ID for a user with caching
  Future<String?> getPartnerId(String userId) async {
    // Check cache first
    if (_partnerCache.containsKey(userId)) {
      Logger.d(_tag, 'Partner ID found in cache for user: $userId');
      return _partnerCache[userId];
    }
    
    try {
      Logger.d(_tag, 'Fetching partner ID for user: $userId');
      
      // Get the user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        Logger.w(_tag, 'User document not found: $userId');
        _partnerCache[userId] = null;
        return null;
      }
      
      final userData = userDoc.data();
      
      // Check if the user has a partner field
      if (userData != null && userData.containsKey('partnerId')) {
        final partnerId = userData['partnerId'] as String?;
        if (partnerId != null && partnerId.isNotEmpty) {
          Logger.i(_tag, 'Found partner ID: $partnerId for user: $userId');
          _partnerCache[userId] = partnerId;
          return partnerId;
        }
      }
      
      // If no direct partner ID, check relationship collection
      final relationshipQuery = await _firestore
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
            final partnerId = user as String;
            Logger.i(_tag, 'Found partner ID from relationship: $partnerId for user: $userId');
            _partnerCache[userId] = partnerId;
            return partnerId;
          }
        }
      }
      
      // User doesn't have a partner yet - this is normal for new users
      Logger.d(_tag, 'No partner found for user: $userId');
      _partnerCache[userId] = null;
      return null;
    } catch (e) {
      Logger.e(_tag, 'Error getting partner ID for user: $userId', e);
      return null;
    }
  }
  
  /// Get partner data including profile information
  Future<Map<String, dynamic>?> getPartnerData(String userId) async {
    final partnerId = await getPartnerId(userId);
    if (partnerId == null) return null;
    
    try {
      final partnerDoc = await _firestore.collection('users').doc(partnerId).get();
      if (partnerDoc.exists) {
        return partnerDoc.data();
      }
      return null;
    } catch (e) {
      Logger.e(_tag, 'Error getting partner data for user: $userId', e);
      return null;
    }
  }
  
  /// Clear cache for a specific user (useful when partner status changes)
  void clearCache(String userId) {
    _partnerCache.remove(userId);
    Logger.d(_tag, 'Cleared partner cache for user: $userId');
  }
  
  /// Clear all cache (useful for logout)
  static void clearAllCache() {
    _partnerCache.clear();
    Logger.d(_tag, 'Cleared all partner cache');
  }
  
  /// Link two users as partners
  Future<bool> linkPartners(String userId1, String userId2) async {
    try {
      Logger.i(_tag, 'Linking partners: $userId1 and $userId2');
      
      final batch = _firestore.batch();
      
      // Update both user documents
      batch.update(_firestore.collection('users').doc(userId1), {
        'partnerId': userId2,
        'profile.partnerId': userId2,
        'profile.relationshipStatus': 'in_relationship',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      batch.update(_firestore.collection('users').doc(userId2), {
        'partnerId': userId1,
        'profile.partnerId': userId1,
        'profile.relationshipStatus': 'in_relationship',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Create or update relationship document
      final relationshipId = _generateRelationshipId(userId1, userId2);
      batch.set(_firestore.collection('relationships').doc(relationshipId), {
        'users': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      
      await batch.commit();
      
      // Update cache
      _partnerCache[userId1] = userId2;
      _partnerCache[userId2] = userId1;
      
      Logger.i(_tag, 'Successfully linked partners');
      return true;
    } catch (e) {
      Logger.e(_tag, 'Failed to link partners', e);
      return false;
    }
  }
  
  /// Unlink partners
  Future<bool> unlinkPartners(String userId1, String userId2) async {
    try {
      Logger.i(_tag, 'Unlinking partners: $userId1 and $userId2');
      
      final batch = _firestore.batch();
      
      // Update both user documents
      batch.update(_firestore.collection('users').doc(userId1), {
        'partnerId': '',
        'profile.partnerId': '',
        'profile.relationshipStatus': 'single',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      batch.update(_firestore.collection('users').doc(userId2), {
        'partnerId': '',
        'profile.partnerId': '',
        'profile.relationshipStatus': 'single',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update relationship document status
      final relationshipId = _generateRelationshipId(userId1, userId2);
      batch.update(_firestore.collection('relationships').doc(relationshipId), {
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      // Clear cache
      clearCache(userId1);
      clearCache(userId2);
      
      Logger.i(_tag, 'Successfully unlinked partners');
      return true;
    } catch (e) {
      Logger.e(_tag, 'Failed to unlink partners', e);
      return false;
    }
  }
  
  /// Generate a consistent relationship ID from two user IDs
  String _generateRelationshipId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
  
  /// Check if two users are partners
  Future<bool> arePartners(String userId1, String userId2) async {
    final partner1 = await getPartnerId(userId1);
    final partner2 = await getPartnerId(userId2);
    
    return partner1 == userId2 && partner2 == userId1;
  }
}
