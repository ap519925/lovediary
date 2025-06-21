part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String userId;
  const LoadProfile(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateProfile extends ProfileEvent {
  final String userId;
  final Map<String, dynamic> updates;
  const UpdateProfile(this.userId, this.updates);

  @override
  List<Object> get props => [userId, updates];
}

class UploadProfileImage extends ProfileEvent {
  final String userId;
  final String imageType;
  final XFile imageFile;
  const UploadProfileImage(this.userId, this.imageType, this.imageFile);

  @override
  List<Object> get props => [userId, imageType, imageFile];
}

class SearchUsersById extends ProfileEvent {
  final String userIdToSearch;
  final String currentUserId;
  const SearchUsersById(this.userIdToSearch, this.currentUserId);

  @override
  List<Object> get props => [userIdToSearch, currentUserId];
}

class SendRelationshipRequest extends ProfileEvent {
  final String fromUserId;
  final String toUserId;
  const SendRelationshipRequest(this.fromUserId, this.toUserId);

  @override
  List<Object> get props => [fromUserId, toUserId];
}

class LoadRelationshipRequests extends ProfileEvent {
  final String currentUserId;
  const LoadRelationshipRequests(this.currentUserId);

  @override
  List<Object> get props => [currentUserId];
}

class AcceptRelationshipRequest extends ProfileEvent {
  final String currentUserId;
  final String requestId;
  const AcceptRelationshipRequest(this.currentUserId, this.requestId);

  @override
  List<Object> get props => [currentUserId, requestId];
}

class DeclineRelationshipRequest extends ProfileEvent {
  final String currentUserId;
  final String requestId;
  const DeclineRelationshipRequest(this.currentUserId, this.requestId);

  @override
  List<Object> get props => [currentUserId, requestId];
}

class LoadDashboardData extends ProfileEvent {
  final String currentUserId;
  const LoadDashboardData(this.currentUserId);

  @override
  List<Object> get props => [currentUserId];
}

class SetAnniversaryDate extends ProfileEvent {
  final String relationshipId;
  final DateTime anniversaryDate;

  const SetAnniversaryDate(this.relationshipId, this.anniversaryDate);

  @override
  List<Object> get props => [relationshipId, anniversaryDate];
}

class UpdateUserLocation extends ProfileEvent {
  final String userId;
  const UpdateUserLocation(this.userId);

  @override
  List<Object> get props => [userId];
}
