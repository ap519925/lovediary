import 'dart:async';
import 'dart:math';
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
    on<AcceptRelationshipRequest>(_onAcceptRelationshipRequest);
    on<RejectRelationshipRequest>(_onRejectRelationshipRequest);
    on<FetchRelationshipRequests>(_onFetchRelationshipRequests);
    on<CreatePost>(_onCreatePost);
    on<FetchPosts>(_onFetchPosts);
    on<UploadPostImage>(_onUploadPostImage);
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
      final snapshot = await firestore
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

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    print('=== STARTING LOAD PROFILE ===');
    print('User ID: ${event.userId}');
    print('Current user: ${auth.currentUser?.uid}');
    
    emit(ProfileLoading());
    
    try {
      // Check authentication first
      if (auth.currentUser == null) {
        print('ERROR: User not authenticated');
        emit(ProfileError('User not authenticated'));
        return;
      }
      
      if (event.userId.isEmpty) {
        print('ERROR: User ID is empty');
        emit(ProfileError('Invalid user ID'));
        return;
      }

      print('Fetching user document from Firestore...');
      final docRef = firestore.collection('users').doc(event.userId);
      final doc = await docRef.get();
      print('Document exists: ${doc.exists}');

      if (!doc.exists) {
        print('Creating new user document...');
        // Create a new user document with basic profile
        final newProfile = <String, dynamic>{
          'displayName': auth.currentUser?.displayName ?? 'Anonymous',
          'email': auth.currentUser?.email ?? '',
          'bio': '',
          'location': '',
          'birthday': '',
          'avatarUrl': null,
          'bannerUrl': null,
          'relationshipStatus': 'single',
          'searchableName': (auth.currentUser?.displayName ?? 'anonymous').toLowerCase(),
        };
        
        // Generate user code
        print('Generating user code...');
        final userCode = await _getUniqueUserCode();
        newProfile['userCode'] = userCode;
        print('Generated user code: $userCode');
        
        // Create the user document
        print('Creating user document in Firestore...');
        await docRef.set({
          'displayName': auth.currentUser?.displayName ?? 'Anonymous',
          'email': auth.currentUser?.email ?? '',
          'userCode': userCode,
          'profile': newProfile,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        print('SUCCESS: Created new user profile');
        print('Profile data: $newProfile');
        emit(ProfileLoaded(newProfile));
        print('=== PROFILE LOADED SUCCESSFULLY ===');
        return;
      }

      final userData = doc.data()!;
      print('Raw user data: $userData');
      
      // Handle case where profile doesn't exist or is null
      Map<String, dynamic> profile;
      if (userData.containsKey('profile') && userData['profile'] != null) {
        profile = Map<String, dynamic>.from(userData['profile'] as Map<String, dynamic>);
        print('Found existing profile in user data');
      } else {
        print('No profile found, creating default profile');
        // Create a default profile if it doesn't exist
        profile = <String, dynamic>{
          'displayName': userData['displayName'] ?? auth.currentUser?.displayName ?? 'Anonymous',
          'email': userData['email'] ?? auth.currentUser?.email ?? '',
          'bio': '',
          'location': '',
          'birthday': '',
          'avatarUrl': null,
          'bannerUrl': null,
          'relationshipStatus': 'single',
          'searchableName': (userData['displayName'] ?? auth.currentUser?.displayName ?? 'anonymous').toLowerCase(),
        };
      }
      
      // Ensure userCode exists
      if (!profile.containsKey('userCode') || profile['userCode'] == null || profile['userCode'] == '') {
        print('UserCode missing, checking root level...');
        // Check if userCode exists at root level
        if (userData.containsKey('userCode') && userData['userCode'] != null && userData['userCode'] != '') {
          profile['userCode'] = userData['userCode'];
          print('Using existing userCode from root: ${userData['userCode']}');
        } else {
          // Generate a new unique code
          print('Generating new userCode...');
          final userCode = await _getUniqueUserCode();
          profile['userCode'] = userCode;
          print('Generated new userCode: $userCode');
          
          // Update the document with the new code (but don't fail if this fails)
          try {
            print('Updating document with new userCode...');
            await docRef.update({
              'userCode': userCode,
              'profile': profile,
            });
            print('Successfully updated user document with new userCode');
          } catch (e) {
            print('Failed to update userCode, but continuing: $e');
          }
        }
      } else {
        print('UserCode already exists: ${profile['userCode']}');
      }
      
      // Ensure profile exists in the document (but don't fail if this fails)
      if (!userData.containsKey('profile') || userData['profile'] == null) {
        try {
          print('Updating document with profile...');
          await docRef.update({'profile': profile});
          print('Successfully updated user document with profile');
        } catch (e) {
          print('Failed to update profile, but continuing: $e');
        }
      }
      
      print('SUCCESS: Profile loaded successfully');
      print('Final profile data: $profile');
      emit(ProfileLoaded(profile));
      print('=== PROFILE LOADED SUCCESSFULLY ===');
      
    } catch (e, stackTrace) {
      print('CRITICAL ERROR in _onLoadProfile: $e');
      print('Stack trace: $stackTrace');
      emit(ProfileError('Failed to load profile: ${e.toString()}'));
      print('=== PROFILE LOAD FAILED ===');
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      // First get the current profile to preserve any fields not being updated
      final doc = await firestore
          .collection('users')
          .doc(event.userId)
          .get();
      
      if (!doc.exists) {
        emit(ProfileError('User not found'));
        return;
      }
      
      final userData = doc.data()!;
      
      // Handle case where profile doesn't exist or is null
      Map<String, dynamic> currentProfile;
      if (userData.containsKey('profile') && userData['profile'] != null) {
        currentProfile = Map<String, dynamic>.from(userData['profile'] as Map<String, dynamic>);
      } else {
        // Create a default profile if it doesn't exist
        currentProfile = <String, dynamic>{
          'displayName': userData['displayName'] ?? 'Anonymous',
          'bio': '',
          'location': '',
          'birthday': '',
          'avatarUrl': null,
          'bannerUrl': null,
          'relationshipStatus': 'single',
          'searchableName': (userData['displayName'] ?? 'anonymous').toLowerCase(),
        };
      }
      
      // Create updates with search field
      final updatesWithSearch = {
        ...event.updates,
        if (event.updates.containsKey('displayName'))
          'searchableName': event.updates['displayName']?.toLowerCase(),
      };
      
      // Preserve the userCode
      if (currentProfile.containsKey('userCode')) {
        updatesWithSearch['userCode'] = currentProfile['userCode'];
      } else if (userData.containsKey('userCode')) {
        updatesWithSearch['userCode'] = userData['userCode'];
      }
      
      // Merge with current profile to preserve other fields
      final mergedProfile = {
        ...currentProfile,
        ...updatesWithSearch,
      };
      
      print('Updating profile with: $mergedProfile'); // Debug log
      
      await firestore.runTransaction((transaction) async {
        final docRef = firestore.collection('users').doc(event.userId);
        transaction.update(docRef, {
          'profile': mergedProfile,
        });
      });

      emit(ProfileLoaded(mergedProfile));
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
      print('Starting profile image upload for user: ${event.userId}');
      print('Image type: ${event.imageType}');
      
      // For web, we need to handle XFile differently
      final bytes = await event.imageFile.readAsBytes();
      print('Image size: ${bytes.length} bytes');
      
      // Check if file size is too large (>5MB for web)
      if (bytes.length > 5 * 1024 * 1024) {
        print('File size too large: ${bytes.length} bytes');
        emit(ProfileError('Image file too large (max 5MB)'));
        return;
      }
      
      // Create a reference to the storage location
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${event.imageType}_$timestamp';
      final ref = storage.ref().child('users/${event.userId}/$fileName');
      
      // Determine content type based on file name
      String contentType = 'image/jpeg';
      final imageFileName = event.imageFile.name.toLowerCase();
      if (imageFileName.endsWith('.png')) {
        contentType = 'image/png';
      } else if (imageFileName.endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (imageFileName.endsWith('.webp')) {
        contentType = 'image/webp';
      }
      
      // Upload the file with metadata - using simplified approach for web
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'userId': event.userId, 'type': event.imageType},
        cacheControl: 'public, max-age=31536000',
      );
      
      print('Starting upload to Firebase Storage: users/${event.userId}/$fileName');
      
      // Use putData for web with retry logic
      UploadTask uploadTask;
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          uploadTask = ref.putData(bytes, metadata);
          
          // Monitor upload progress
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
          });
          
          // Wait for upload to complete with timeout
          await uploadTask.timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              throw TimeoutException('Upload timed out after 2 minutes');
            },
          );
          
          print('Upload completed successfully');
          break; // Success, exit retry loop
          
        } catch (e) {
          retryCount++;
          print('Upload attempt $retryCount failed: $e');
          
          if (retryCount >= maxRetries) {
            rethrow; // Re-throw the error if max retries reached
          }
          
          // Wait before retrying
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
      
      // Get the download URL
      final url = await ref.getDownloadURL();
      print('Download URL obtained: $url');

      // Update the user profile with the image URL
      await firestore.runTransaction((transaction) async {
        final docRef = firestore.collection('users').doc(event.userId);
        transaction.update(docRef, {
          'profile.${event.imageType}Url': url,
        });
      });
      
      print('Profile updated with new image URL');
      emit(ProfileImageUploaded(url));
      
    } catch (e, stackTrace) {
      print('Error uploading profile image: $e');
      print('Stack trace: $stackTrace');
      
      // Check for specific error types
      String errorMessage = 'Failed to upload image';
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
        
        if (e.code == 'unauthorized' || e.code == 'permission-denied') {
          errorMessage = 'Permission denied: Check Firebase Storage rules';
        } else if (e.code == 'canceled') {
          errorMessage = 'Upload was canceled';
        } else if (e.code == 'storage/quota-exceeded') {
          errorMessage = 'Storage quota exceeded';
        } else if (e.code == 'storage/object-not-found') {
          errorMessage = 'Storage path not found';
        } else if (e.code == 'storage/bucket-not-found') {
          errorMessage = 'Storage bucket not found';
        } else if (e.message?.contains('CORS') == true) {
          errorMessage = 'CORS error: Please configure Firebase Storage CORS policy';
        } else {
          errorMessage = 'Firebase Storage error: ${e.code} - ${e.message}';
        }
      } else if (e is TimeoutException) {
        errorMessage = 'Upload timed out: Try a smaller image or check your connection';
      } else {
        errorMessage = 'Upload failed: ${e.toString()}';
      }
      
      emit(ProfileError(errorMessage));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileSearching());
    try {
      final query = event.query.trim();
      
      // Check if the query looks like a user code (6 characters, alphanumeric)
      final isUserCode = query.length == 6 && RegExp(r'^[A-Z0-9]+$').hasMatch(query);
      
      QuerySnapshot snapshot;
      
      if (isUserCode) {
        // Search by user code (exact match)
        snapshot = await firestore.collection('users')
          .where('userCode', isEqualTo: query)
          .get();
      } else {
        // Search by display name (partial match)
        final queryLower = query.toLowerCase();
        snapshot = await firestore.collection('users')
          .where('profile.searchableName', isGreaterThanOrEqualTo: queryLower)
          .where('profile.searchableName', isLessThan: '${queryLower}z')
          .get();
      }
      
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
      // First check if a request already exists in either direction
      final existingRequestQuery1 = await firestore
          .collection('relationship_requests')
          .where('fromUserId', isEqualTo: event.fromUserId)
          .where('toUserId', isEqualTo: event.toUserId)
          .where('status', isEqualTo: 'pending')
          .get();
          
      final existingRequestQuery2 = await firestore
          .collection('relationship_requests')
          .where('fromUserId', isEqualTo: event.toUserId)
          .where('toUserId', isEqualTo: event.fromUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Also check if an active relationship already exists
      final existingRelationshipQuery1 = await firestore
          .collection('relationships')
          .where('user1Id', isEqualTo: event.fromUserId)
          .where('user2Id', isEqualTo: event.toUserId)
          .where('status', isEqualTo: 'active')
          .get();
          
      final existingRelationshipQuery2 = await firestore
          .collection('relationships')
          .where('user1Id', isEqualTo: event.toUserId)
          .where('user2Id', isEqualTo: event.fromUserId)
          .where('status', isEqualTo: 'active')
          .get();
      
      if (!existingRequestQuery1.docs.isEmpty || !existingRequestQuery2.docs.isEmpty) {
        emit(ProfileError('A relationship request already exists between these users'));
        return;
      }
      
      if (!existingRelationshipQuery1.docs.isEmpty || !existingRelationshipQuery2.docs.isEmpty) {
        emit(ProfileError('These users are already in a relationship'));
        return;
      }
      
      // Create the relationship request
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
  
  Future<void> _onAcceptRelationshipRequest(
    AcceptRelationshipRequest event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      // Get the request document
      final requestDoc = await firestore
          .collection('relationship_requests')
          .doc(event.requestId)
          .get();
          
      if (!requestDoc.exists) {
        emit(ProfileError('Relationship request not found'));
        return;
      }
      
      final requestData = requestDoc.data()!;
      final fromUserId = requestData['fromUserId'] as String;
      final toUserId = requestData['toUserId'] as String;
      
      // Update the request status to 'accepted'
      await firestore.runTransaction((transaction) async {
        transaction.update(requestDoc.reference, {
          'status': 'accepted',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Create a new relationship document
        final relationshipsRef = firestore.collection('relationships');
        transaction.set(relationshipsRef.doc(), {
          'user1Id': fromUserId,
          'user2Id': toUserId,
          'status': 'active',
          'anniversaryDate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'requestId': requestDoc.id,
          },
        });
        
        // Update both users' profiles with relationship status
        final user1Ref = firestore.collection('users').doc(fromUserId);
        final user2Ref = firestore.collection('users').doc(toUserId);
        
        transaction.update(user1Ref, {
          'profile.relationshipStatus': 'in_relationship',
          'profile.partnerId': toUserId,
        });
        
        transaction.update(user2Ref, {
          'profile.relationshipStatus': 'in_relationship',
          'profile.partnerId': fromUserId,
        });
      });
      
      emit(RelationshipRequestAccepted());
    } catch (e) {
      emit(ProfileError('Failed to accept request: ${e.toString()}'));
    }
  }
  
  Future<void> _onRejectRelationshipRequest(
    RejectRelationshipRequest event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      // Get the request document
      final requestDoc = await firestore
          .collection('relationship_requests')
          .doc(event.requestId)
          .get();
          
      if (!requestDoc.exists) {
        emit(ProfileError('Relationship request not found'));
        return;
      }
      
      // Update the request status to 'rejected'
      await firestore.runTransaction((transaction) async {
        transaction.update(requestDoc.reference, {
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      emit(RelationshipRequestRejected());
    } catch (e) {
      emit(ProfileError('Failed to reject request: ${e.toString()}'));
    }
  }
  
  Future<void> _onFetchRelationshipRequests(
    FetchRelationshipRequests event,
    Emitter<ProfileState> emit,
  ) async {
    // Don't emit ProfileLoading here to avoid overriding ProfileLoaded state
    try {
      // Get incoming requests
      final incomingRequestsQuery = await firestore
          .collection('relationship_requests')
          .where('toUserId', isEqualTo: event.userId)
          .where('status', isEqualTo: 'pending')
          .get();
          
      // Get outgoing requests
      final outgoingRequestsQuery = await firestore
          .collection('relationship_requests')
          .where('fromUserId', isEqualTo: event.userId)
          .where('status', isEqualTo: 'pending')
          .get();
          
      // Get active relationship
      final relationshipQuery1 = await firestore
          .collection('relationships')
          .where('user1Id', isEqualTo: event.userId)
          .where('status', isEqualTo: 'active')
          .get();
          
      final relationshipQuery2 = await firestore
          .collection('relationships')
          .where('user2Id', isEqualTo: event.userId)
          .where('status', isEqualTo: 'active')
          .get();
      
      final incomingRequests = incomingRequestsQuery.docs;
      final outgoingRequests = outgoingRequestsQuery.docs;
      final relationships = [...relationshipQuery1.docs, ...relationshipQuery2.docs];
      
      emit(RelationshipRequestsLoaded(
        incomingRequests: incomingRequests,
        outgoingRequests: outgoingRequests,
        relationships: relationships,
      ));
    } catch (e) {
      // Don't emit ProfileError for relationship requests - just log it
      print('Failed to fetch relationship requests: ${e.toString()}');
      // Emit an empty relationship requests state instead
      emit(RelationshipRequestsLoaded(
        incomingRequests: [],
        outgoingRequests: [],
        relationships: [],
      ));
    }
  }
  
  Future<void> _onCreatePost(
    CreatePost event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      // Get user profile data
      final userDoc = await firestore.collection('users').doc(event.userId).get();
      final userData = userDoc.data();
      final userProfile = userData?['profile'] as Map<String, dynamic>? ?? {};
      
      // Create a new post document with user data
      await firestore.collection('posts').add({
        'userId': event.userId,
        'content': event.content,
        'imageUrl': event.imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': [],
        'userName': userProfile['displayName'] ?? 'Anonymous',
        'userProfileImage': userProfile['avatarUrl'],
      });
      
      emit(PostCreated());
      
      // Fetch updated posts
      add(FetchPosts(event.userId));
    } catch (e) {
      emit(ProfileError('Failed to create post: ${e.toString()}'));
    }
  }
  
  Future<void> _onFetchPosts(
    FetchPosts event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    print('=== FETCHING POSTS ===');
    print('User ID: ${event.userId}');
    
    try {
      // Get posts for the user
      final snapshot = await firestore
          .collection('posts')
          .where('userId', isEqualTo: event.userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${snapshot.docs.length} posts for user ${event.userId}');
      
      if (snapshot.docs.isEmpty) {
        print('No posts found for user');
        emit(PostsLoaded([]));
        return;
      }
      
      // Log each post for debugging
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Post ${doc.id}: ${data['content']?.toString().substring(0, 50) ?? 'No content'}...');
      }
      
      emit(PostsLoaded(snapshot.docs));
      print('=== POSTS LOADED SUCCESSFULLY ===');
    } catch (e, stackTrace) {
      print('=== ERROR FETCHING POSTS ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'Failed to load posts';
      if (e.toString().contains('index')) {
        errorMessage = 'Database needs configuration - please wait a few minutes and try again.\n'
                      'If the issue persists, visit Firebase Console > Firestore > Indexes '
                      'to create the required composite index.';
        print('FIRESTORE INDEX ERROR: Missing composite index for posts query');
        print('Required index fields: userId (ascending), createdAt (descending)');
        print('Auto-indexing may take a few minutes to complete');
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied - please check your account permissions';
        print('FIRESTORE PERMISSION ERROR: Check security rules for posts collection');
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network connection failed - please check your internet and try again';
        print('NETWORK ERROR: Connection to Firestore failed');
      }
      
      emit(ProfileError(errorMessage));
      print('=== EMITTED ERROR STATE ===');
    }
  }
  
  Future<void> _onUploadPostImage(
    UploadPostImage event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    int attempt = 0;
    
    while (attempt < maxRetryAttempts) {
      try {
        print('Uploading post image, attempt ${attempt + 1}');
        
        // Read file bytes directly from XFile (works on all platforms)
        final bytes = await event.imageFile.readAsBytes();
        print('Post image file size: ${bytes.length} bytes');
        
        // Check if file size is too large (>10MB)
        if (bytes.length > 10 * 1024 * 1024) {
          print('File size too large: ${bytes.length} bytes');
          emit(ProfileError('Image file too large (max 10MB)'));
          return;
        }
        
        // Generate a unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = '${event.userId}_post_$timestamp';
        
        // Create a reference to the storage location
        final ref = storage.ref().child('posts/$filename');
        
        // Determine content type based on file name
        String contentType = 'image/jpeg';
        final imageFileName = event.imageFile.name.toLowerCase();
        if (imageFileName.endsWith('.png')) {
          contentType = 'image/png';
        } else if (imageFileName.endsWith('.gif')) {
          contentType = 'image/gif';
        } else if (imageFileName.endsWith('.webp')) {
          contentType = 'image/webp';
        }
        
        // Upload the file with metadata using putData (works on all platforms)
        final metadata = SettableMetadata(
          contentType: contentType,
          customMetadata: {'userId': event.userId, 'type': 'post'},
          cacheControl: 'public, max-age=31536000',
        );
        
        print('Starting post image upload to Firebase Storage');
        final uploadTask = ref.putData(bytes, metadata);
        
        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('Post upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        });
        
        // Wait for upload to complete with timeout
        await uploadTask.timeout(const Duration(minutes: 2), onTimeout: () {
          throw TimeoutException('Upload timed out after 2 minutes');
        });
        print('Post image upload completed');
        
        // Get the download URL
        final url = await ref.getDownloadURL();
        print('Post image download URL: $url');
        
        emit(PostImageUploaded(url));
        return; // Success, exit the retry loop
      } catch (e) {
        attempt++;
        print('Error uploading post image (attempt $attempt): ${e.toString()}');
        
        // Check for specific error types
        String errorMessage = 'Failed to upload image';
        if (e is FirebaseException) {
          print('Firebase error code: ${e.code}');
          print('Firebase error message: ${e.message}');
          
          if (e.code == 'unauthorized' || e.code == 'permission-denied') {
            errorMessage = 'Permission denied: Check Firebase Storage rules';
          } else if (e.code == 'canceled') {
            errorMessage = 'Upload was canceled';
          } else if (e.code == 'storage/quota-exceeded') {
            errorMessage = 'Storage quota exceeded';
          } else if (e.code == 'storage/object-not-found') {
            errorMessage = 'Storage path not found';
          } else if (e.code == 'storage/bucket-not-found') {
            errorMessage = 'Storage bucket not found';
          } else if (e.message?.contains('CORS') == true) {
            errorMessage = 'CORS error: Please configure Firebase Storage CORS policy';
          } else {
            errorMessage = 'Firebase Storage error: ${e.code} - ${e.message}';
          }
        } else if (e is TimeoutException) {
          errorMessage = 'Upload timed out: Try a smaller image or check your connection';
        } else {
          errorMessage = 'Upload failed: ${e.toString()}';
        }
        
        if (attempt >= maxRetryAttempts) {
          print('Max retry attempts reached for post image, giving up');
          emit(ProfileError('$errorMessage after $maxRetryAttempts attempts'));
        } else {
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }
}
