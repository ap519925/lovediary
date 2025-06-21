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

class SearchUsers extends ProfileEvent {
  final String query;
  final String userId;
  const SearchUsers(this.query, this.userId);

  @override
  List<Object> get props => [query, userId];
}

class SendRelationshipRequest extends ProfileEvent {
  final String fromUserId;
  final String toUserId;
  const SendRelationshipRequest(this.fromUserId, this.toUserId);

  @override
  List<Object> get props => [fromUserId, toUserId];
}
