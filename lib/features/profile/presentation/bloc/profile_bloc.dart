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
    on<SearchUsersById>(_onSearchUsersById); // Changed to handle ID search
    on<SendRelationshipRequest>(_onSendRelationshipRequest);
    on<LoadRelationshipRequests>(_onLoadRelationshipRequests); // New event handler
    on<AcceptRelationshipRequest>(_onAcceptRelationshipRequest); // New event handler
    on<DeclineRelationshipRequest>(_onDeclineRelationshipRequest); // New event handler
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

  Future<void> _onSearchUsersById( // Updated method name and logic
    SearchUsersById event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileSearching());
    try {
      final snapshot = await firestore.collection('users')
        .where('userId', isEqualTo: event.userIdToSearch)
        .get(const GetOptions(source: Source.server));
      
      final results = snapshot.docs.where((doc) => doc.id != event.currentUserId).toList();
      if (results.isNotEmpty) {
        emit(ProfileSearchResults(results));
      } else {
        emit(ProfileError('No user found with that ID.'));
      }
    } catch (e) {
      emit(ProfileError('Search failed: ${e.toString()}'));
    }
  }

  Future<void> _onSendRelationshipRequest(
    SendRelationshipRequest event,
    Emitter<ProfileState> emit,
  ) async {
    emit(RelationshipRequestLoading());
    try {
      // Check if a request already exists between these users
      final existingRequests = await firestore.collection('relationship_requests')
          .where('fromUserId', isEqualTo: event.fromUserId)
          .where('toUserId', isEqualTo: event.toUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      final existingReverseRequests = await firestore.collection('relationship_requests')
          .where('fromUserId', isEqualTo: event.toUserId)
          .where('toUserId', isEqualTo: event.fromUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequests.docs.isNotEmpty || existingReverseRequests.docs.isNotEmpty) {
        emit(ProfileError('A pending request already exists with this user.'));
        return;
      }


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

  Future<void> _onLoadRelationshipRequests(
    LoadRelationshipRequests event,
    Emitter<ProfileState> emit,
  ) async {
    emit(RelationshipRequestLoading());
    try {
      final snapshot = await firestore.collection('relationship_requests')
          .where('toUserId', isEqualTo: event.currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (snapshot.docs.isNotEmpty) {
        emit(RelationshipRequestsLoaded(snapshot.docs));
      } else {
        emit(NoRelationshipRequests());
      }
    } catch (e) {
      emit(ProfileError('Failed to load requests: ${e.toString()}'));
    }
  }

  Future<void> _onAcceptRelationshipRequest(
    AcceptRelationshipRequest event,
    Emitter<ProfileState> emit,
  ) async {
    emit(RelationshipRequestLoading());
    try {
      await firestore.runTransaction((transaction) async {
        final requestDoc = await transaction.get(
            firestore.collection('relationship_requests').doc(event.requestId));

        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final fromUserId = requestDoc.data()!['fromUserId'];
        final toUserId = requestDoc.data()!['toUserId'];

        // Get current timestamp for relationship start date
        final Timestamp now = Timestamp.now();

        // Update request status
        transaction.update(requestDoc.reference, {'status': 'accepted'});

        // Link partners in user profiles and set relationship start date
        transaction.update(firestore.collection('users').doc(fromUserId), {
          'profile.partnerId': toUserId,
          'profile.relationshipStatus': 'linked',
          'profile.relationshipStartDate': now,
          'profile.anniversaryDate': now, // Set anniversary to start date initially
        });
        transaction.update(firestore.collection('users').doc(toUserId), {
          'profile.partnerId': fromUserId,
          'profile.relationshipStatus': 'linked',
          'profile.relationshipStartDate': now,
          'profile.anniversaryDate': now, // Set anniversary to start date initially
        });
      });
      emit(RelationshipRequestAccepted());
    } catch (e) {
      emit(ProfileError('Failed to accept request: ${e.toString()}'));
    }
  }

  Future<void> _onDeclineRelationshipRequest(
    DeclineRelationshipRequest event,
    Emitter<ProfileState> emit,
  ) async {
    emit(RelationshipRequestLoading());
    try {
      await firestore.runTransaction((transaction) async {
        final requestDoc = firestore.collection('relationship_requests').doc(event.requestId);
        transaction.update(requestDoc, {'status': 'declined'});
      });
      emit(RelationshipRequestDeclined());
    } catch (e) {
      emit(ProfileError('Failed to decline request: ${e.toString()}'));
    }
  }
}
