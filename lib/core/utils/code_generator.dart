import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Utility class for generating unique codes
class CodeGenerator {
  /// Generate a unique user code (6 characters, alphanumeric)
  static String generateUniqueUserCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  /// Check if a user code already exists in Firestore
  static Future<bool> userCodeExists(
    FirebaseFirestore firestore, 
    String code
  ) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .where('userCode', isEqualTo: code)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if code exists: $e');
      return false; // Assume code doesn't exist if there's an error
    }
  }
  
  /// Generate a unique user code that doesn't exist yet in Firestore
  static Future<String> getUniqueUserCode(FirebaseFirestore firestore) async {
    String code;
    bool exists;
    int attempts = 0;
    
    try {
      do {
        code = generateUniqueUserCode();
        exists = await userCodeExists(firestore, code);
        attempts++;
      } while (exists && attempts < 10); // Limit attempts to avoid infinite loop
      
      if (attempts >= 10) {
        // Fallback to a timestamp-based code
        code = 'U${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      }
      
      return code;
    } catch (e) {
      // Fallback to a timestamp-based code
      code = 'U${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      return code;
    }
  }
}
