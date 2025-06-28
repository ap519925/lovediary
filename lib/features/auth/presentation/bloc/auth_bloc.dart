import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovediary/core/services/error_reporting_service.dart';
import 'package:lovediary/core/utils/code_generator.dart';
import 'package:lovediary/core/utils/logger.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const String _tag = 'AuthBloc';
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
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LinkPartnerRequested>(_onLinkPartnerRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    Logger.i(_tag, 'Login requested for email: ${event.email}');
    try {
      UserCredential? userCredential;
      
      // If password is empty, user is already authenticated (from auth state persistence)
      if (event.password.isEmpty) {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          Logger.i(_tag, 'Using existing authenticated user');
          // Create a mock UserCredential for existing user
          userCredential = null; // We'll handle this case separately
        } else {
          throw Exception('No authenticated user found');
        }
      } else {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
      }
      
      final user = userCredential?.user ?? _auth.currentUser;
      if (user == null) {
        throw Exception('Authentication failed - no user found');
      }
      
      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        emit(AuthAuthenticated(user, userData: userData));
      } else {
        // If user document doesn't exist (rare case), create a new one
        Logger.i(_tag, 'User document not found, creating new one');
        final userCode = await CodeGenerator.getUniqueUserCode(_firestore);
        final userData = {
          'email': user.email ?? event.email,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
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
        
        await _firestore.collection('users').doc(user.uid).set(userData);
        emit(AuthAuthenticated(user, userData: userData));
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Login failed', e, stackTrace);
      
      // Report the error
      ErrorReportingService.logError(
        e, 
        stackTrace,
        reason: 'Login failed',
        information: {
          'email': event.email,
          'method': 'email/password',
        },
      );
      
      // Emit failure state with user-friendly message
      String errorMessage = 'Login failed';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password provided';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many login attempts. Try again later';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          default:
            errorMessage = 'Authentication failed: ${e.message}';
        }
      }
      
      emit(AuthFailure(errorMessage));
    }
  }


  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    Logger.i(_tag, 'Registration requested for email: ${event.email}');
    try {
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      Logger.i(_tag, 'User created with UID: ${userCredential.user!.uid}');
      
      // Generate a unique user code
      Logger.d(_tag, 'Generating unique user code');
      final userCode = await CodeGenerator.getUniqueUserCode(_firestore);
      Logger.i(_tag, 'Generated unique code: $userCode');
      
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
      Logger.d(_tag, 'Saving user data to Firestore');
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
      Logger.i(_tag, 'User data saved to Firestore');
      
      // Emit authenticated state with user data
      emit(AuthAuthenticated(userCredential.user!, userData: userData));
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Registration failed', e, stackTrace);
      
      // Report the error
      ErrorReportingService.logError(
        e, 
        stackTrace,
        reason: 'Registration failed',
        information: {
          'email': event.email,
          'method': 'email/password',
        },
      );
      
      // Emit failure state with user-friendly message
      String errorMessage = 'Registration failed';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already in use';
            break;
          case 'weak-password':
            errorMessage = 'The password is too weak';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }
      }
      
      emit(AuthFailure(errorMessage));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    Logger.i(_tag, 'Checking auth status');
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        Logger.i(_tag, 'User is authenticated: ${currentUser.uid}');
        
        // Fetch user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          emit(AuthAuthenticated(currentUser, userData: userData));
        } else {
          Logger.w(_tag, 'User document not found, signing out');
          await _auth.signOut();
          emit(AuthUnauthenticated());
        }
      } else {
        Logger.i(_tag, 'No authenticated user found');
        emit(AuthUnauthenticated());
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error checking auth status', e, stackTrace);
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    Logger.i(_tag, 'Logout requested');
    await _auth.signOut();
    Logger.i(_tag, 'User signed out');
    emit(AuthUnauthenticated());
  }

  Future<void> _onLinkPartnerRequested(
    LinkPartnerRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    Logger.i(_tag, 'Link partner requested: ${event.partnerId}');
    try {
      final partnerDoc = await _firestore.collection('users').doc(event.partnerId).get();
      if (!partnerDoc.exists) {
        Logger.w(_tag, 'Partner not found: ${event.partnerId}');
        emit(AuthFailure('Partner not found'));
        return;
      }

      final batch = _firestore.batch();
      // Update both user documents with partner information
      batch.update(_firestore.collection('users').doc(event.userId), {
        'partnerId': event.partnerId,
        'profile.partnerId': event.partnerId,
        'profile.relationshipStatus': 'in_relationship',
      });
      batch.update(_firestore.collection('users').doc(event.partnerId), {
        'partnerId': event.userId,
        'profile.partnerId': event.userId,
        'profile.relationshipStatus': 'in_relationship',
      });
      await batch.commit();
      Logger.i(_tag, 'Partner linked successfully');
      
      emit(PartnerLinkedSuccessfully());
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Failed to link partner', e, stackTrace);
      
      // Report the error
      ErrorReportingService.logError(
        e, 
        stackTrace,
        reason: 'Partner linking failed',
        information: {
          'userId': event.userId,
          'partnerId': event.partnerId,
        },
      );
      
      // Emit failure state with user-friendly message
      emit(AuthFailure('Failed to link partner. Please try again later.'));
    }
  }
}
