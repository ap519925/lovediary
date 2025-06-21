import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': event.email,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userCredential.user!.uid,
        'profile': {
          'name': '',
          'displayName': '',
          'gender': '',
          'avatarUrl': '',
          'bannerUrl': '',
          'relationshipPoints': 0,
          'partnerId': '',
          'relationshipStatus': 'single',
          'searchableName': '' // For case-insensitive search
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
