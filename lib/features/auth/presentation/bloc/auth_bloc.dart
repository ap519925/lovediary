import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FirebaseMessaging
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
      // Get FCM token and save it to user document
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'fcmToken': fcmToken,
        });
      }
      emit(AuthAuthenticated(userCredential.user!));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      // Get FCM token and save it to user document during registration
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': event.email,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userCredential.user!.uid,
        'fcmToken': fcmToken, // Save FCM token here
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
          'relationshipStartDate': null, // Added for relationship stats
          'anniversaryDate': null,       // Added for relationship stats
        }
      });
      emit(AuthAuthenticated(userCredential.user!));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Optionally remove FCM token from Firestore on logout
    // final currentUser = _auth.currentUser;
    // if (currentUser != null) {
    //   await _firestore.collection('users').doc(currentUser.uid).update({'fcmToken': FieldValue.delete()});
    // }
    await _auth.signOut();
    emit(AuthUnauthenticated());
  }
}
