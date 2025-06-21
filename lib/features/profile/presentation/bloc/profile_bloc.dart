import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FirebaseAuth auth;
  static const maxRetryAttempts = 3;

  ProfileBloc({
    required this.firestore,
    required this.storage,
    required this.auth,
  }) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<SearchUsers>(_onSearchUsers);
    on<SendRelationshipRequest>(_onSendRelationshipRequest);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    int attempt = 0;
    bool success = false;

    if (auth.currentUser == null) {
      emit(ProfileError('User not authenticated'));
      return;
    }

    while (attempt < maxRetryAttempts && !success) {
      try {
        final doc = await firestore
            .collection('users')
            .doc(event.userId)
            .get(const GetOptions(source: Source.server));

        if (doc.exists) {
          emit(ProfileLoaded(doc.data()!['profile']));
          success = true;
        } else {
          emit(ProfileError('User not found'));
          break;
        }
      } catch (e) {
        attempt++;
        if (attempt >= maxRetryAttempts) {
          emit(ProfileError('Failed to load profile: ${e.toString()}'));
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final updatesWithSearch = {
        ...event.updates,
        if (event.updates.containsKey('displayName'))
          'searchableName': event.updates['displayName']?.toLowerCase(),
      };
      
      await firestore.runTransaction((transaction) async {
        final docRef = firestore.collection('users').doc(event.userId);
        transaction.update(docRef, {
          'profile': updatesWithSearch,
        });
      });

      emit(ProfileLoaded(updatesWithSearch));
    } catch (e) {
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImage event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final ref = storage.ref().child('${event.userId}/${event.imageType}');
      await ref.putFile(File(event.imageFile.path));
      final url = await ref.getDownloadURL();

      await firestore.runTransaction((transaction) async {
        final docRef = firestore.collection('users').doc(event.userId);
        transaction.update(docRef, {
          'profile.${event.imageType}Url': url,
        });
      });

      emit(ProfileImageUploaded(url));
    } catch (e) {
      emit(ProfileError('Failed to upload image: ${e.toString()}'));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileSearching());
    try {
      final queryLower = event.query.toLowerCase();
      final snapshot = await firestore.collection('users')
        .where('profile.searchableName', isGreaterThanOrEqualTo: queryLower)
        .where('profile.searchableName', isLessThan: '${queryLower}z')
        .get(const GetOptions(source: Source.server));
      
      final results = snapshot.docs.where((doc) => doc.id != event.userId).toList();
      emit(ProfileSearchResults(results));
    } catch (e) {
      emit(ProfileError('Search failed: ${e.toString()}'));
    }
  }

  Future<void> _onSendRelationshipRequest(
    SendRelationshipRequest event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await firestore.runTransaction((transaction) async {
        final requestsRef = firestore.collection('relationship_requests');
        transaction.set(requestsRef.doc(), {
          'fromUserId': event.fromUserId,
          'toUserId': event.toUserId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      emit(RelationshipRequestSent());
    } catch (e) {
      emit(ProfileError('Failed to send request: ${e.toString()}'));
    }
  }
}
