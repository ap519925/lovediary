part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
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
  final List<DocumentSnapshot> results;
  const ProfileSearchResults(this.results);

  @override
  List<Object> get props => [results];
}

class RelationshipRequestSent extends ProfileState {}

class RelationshipRequestAccepted extends ProfileState {}

class RelationshipRequestDeclined extends ProfileState {}

class RelationshipRequestLoading extends ProfileState {}

class RelationshipRequestsLoaded extends ProfileState {
  final List<DocumentSnapshot> requests;
  const RelationshipRequestsLoaded(this.requests);

  @override
  List<Object> get props => [requests];
}

class NoRelationshipRequests extends ProfileState {}

class ProfileSearchError extends ProfileState {
  final String message;
  const ProfileSearchError(this.message);

  @override
  List<Object> get props => [message];
}

class DashboardDataLoading extends ProfileState {}

class DashboardDataLoaded extends ProfileState {
  final Map<String, dynamic> userProfile;
  final Map<String, dynamic>? partnerProfile;
  final Map<String, dynamic>? relationshipData;

  const DashboardDataLoaded({
    required this.userProfile,
    this.partnerProfile,
    this.relationshipData,
  });

  @override
  List<Object?> get props => [userProfile, partnerProfile, relationshipData];
}
