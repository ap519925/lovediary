import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthBloc({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore,
        super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<LinkPartnerRequested>(_onLinkPartnerRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        emit(AuthAuthenticated(userCredential.user!, userData: userData));
      } else {
        // If user document doesn't exist (rare case), create a new one
        final userCode = await _getUniqueUserCode();
        final userData = {
          'email': event.email,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userCredential.user!.uid,
          'userCode': userCode,
          'profile': {
            'name': '',
            'displayName': '',
            'gender': '',
            'avatarUrl': '',
            'bannerUrl': '',
            'relationshipPoints': 0,
            'partnerId': '',
            'relationshipStatus': 'single',
            'searchableName': '',
            'userCode': userCode,
            'birthday': '',
            'location': '',
            'anniversaryDate': null,
            'nextMeetingDate': null,
            'bio': ''
          }
        };
        
        await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
        emit(AuthAuthenticated(userCredential.user!, userData: userData));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // Generate a unique user code (6 characters, alphanumeric)
  String _generateUniqueUserCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
    print('Generated code: $code'); // Debug log
    return code;
  }
  
  // Check if a user code already exists
  Future<bool> _userCodeExists(String code) async {
    try {
      print('Checking if code exists: $code'); // Debug log
      final snapshot = await _firestore
          .collection('users')
          .where('userCode', isEqualTo: code)
          .limit(1)
          .get();
      final exists = snapshot.docs.isNotEmpty;
      print('Code exists: $exists'); // Debug log
      return exists;
    } catch (e) {
      print('Error checking if code exists: $e'); // Debug log
      return false; // Assume code doesn't exist if there's an error
    }
  }
  
  // Generate a unique user code that doesn't exist yet
  Future<String> _getUniqueUserCode() async {
    String code;
    bool exists;
    int attempts = 0;
    
    try {
      do {
        code = _generateUniqueUserCode();
        exists = await _userCodeExists(code);
        attempts++;
        print('Attempt $attempts: Code $code exists: $exists'); // Debug log
      } while (exists && attempts < 10); // Limit attempts to avoid infinite loop
      
      if (attempts >= 10) {
        print('Failed to generate unique code after 10 attempts'); // Debug log
        // Fallback to a timestamp-based code
        code = 'U${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        print('Using fallback code: $code'); // Debug log
      }
      
      return code;
    } catch (e) {
      print('Error generating unique code: $e'); // Debug log
      // Fallback to a timestamp-based code
      code = 'U${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      print('Using fallback code due to error: $code'); // Debug log
      return code;
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      print('Starting registration process'); // Debug log
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      print('User created with UID: ${userCredential.user!.uid}'); // Debug log
      
      // Generate a unique user code
      print('Generating unique user code'); // Debug log
      final userCode = await _getUniqueUserCode();
      print('Generated unique code: $userCode'); // Debug log
      
      // Create user data with the unique code
      final userData = {
        'email': event.email,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userCredential.user!.uid,
        'userCode': userCode,
        'profile': {
          'name': '',
          'displayName': '',
          'gender': '',
          'avatarUrl': '',
          'bannerUrl': '',
          'relationshipPoints': 0,
          'partnerId': '',
          'relationshipStatus': 'single',
          'searchableName': '', // For case-insensitive search
          'userCode': userCode, // Also store in profile for easy access
          'birthday': '',
          'location': '',
          'anniversaryDate': null,
          'nextMeetingDate': null,
          'bio': ''
        }
      };
      
      // Save user data to Firestore
      print('Saving user data to Firestore'); // Debug log
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
      print('User data saved to Firestore'); // Debug log
      
      // Emit authenticated state with user data
      print('Emitting AuthAuthenticated state with user data'); // Debug log
      emit(AuthAuthenticated(userCredential.user!, userData: userData));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _auth.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onLinkPartnerRequested(
    LinkPartnerRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final partnerDoc = await _firestore.collection('users').doc(event.partnerId).get();
      if (!partnerDoc.exists) {
        emit(AuthFailure('Partner not found'));
        return;
      }

      final batch = _firestore.batch();
      batch.update(_firestore.collection('users').doc(event.userId), {
        'partnerId': event.partnerId,
      });
      batch.update(_firestore.collection('users').doc(event.partnerId), {
        'partnerId': event.userId,
      });
      await batch.commit();
      
      emit(PartnerLinkedSuccessfully());
    } catch (e) {
      emit(AuthFailure('Failed to link partner: ${e.toString()}'));
    }
  }
}
