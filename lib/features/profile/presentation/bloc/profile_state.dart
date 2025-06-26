part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> profile;
  const ProfileLoaded(this.profile);

  @override
  List<Object> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}

class ProfileImageUploaded extends ProfileState {
  final String imageUrl;
  const ProfileImageUploaded(this.imageUrl);

  @override
  List<Object> get props => [imageUrl];
}

class ProfileSearching extends ProfileState {}

class ProfileSearchResults extends ProfileState {
  final List<QueryDocumentSnapshot> results;
  const ProfileSearchResults(this.results);

  @override
  List<Object> get props => [results];
}

class RelationshipRequestSent extends ProfileState {}

class RelationshipRequestAccepted extends ProfileState {}

class RelationshipRequestRejected extends ProfileState {}

class RelationshipRequestsLoaded extends ProfileState {
  final List<QueryDocumentSnapshot> incomingRequests;
  final List<QueryDocumentSnapshot> outgoingRequests;
  final List<QueryDocumentSnapshot> relationships;
  
  const RelationshipRequestsLoaded({
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.relationships,
  });

  @override
  List<Object> get props => [incomingRequests, outgoingRequests, relationships];
}

class PostImageUploaded extends ProfileState {
  final String imageUrl;
  PostImageUploaded(this.imageUrl);

  @override
  List<Object> get props => [imageUrl];
}

class PostsLoaded extends ProfileState {
  final List<QueryDocumentSnapshot> posts;
  PostsLoaded(this.posts);

  @override
  List<Object> get props => [posts];
}

class PostCreated extends ProfileState {}
