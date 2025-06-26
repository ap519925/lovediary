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

class AcceptRelationshipRequest extends ProfileEvent {
  final String requestId;
  const AcceptRelationshipRequest(this.requestId);

  @override
  List<Object> get props => [requestId];
}

class RejectRelationshipRequest extends ProfileEvent {
  final String requestId;
  const RejectRelationshipRequest(this.requestId);

  @override
  List<Object> get props => [requestId];
}

class FetchRelationshipRequests extends ProfileEvent {
  final String userId;
  const FetchRelationshipRequests(this.userId);

  @override
  List<Object> get props => [userId];
}

class CreatePost extends ProfileEvent {
  final String userId;
  final String content;
  final String? imageUrl;
  const CreatePost(this.userId, this.content, {this.imageUrl});

  @override
  List<Object> get props => [userId, content];
}

class FetchPosts extends ProfileEvent {
  final String userId;
  const FetchPosts(this.userId);

  @override
  List<Object> get props => [userId];
}

class UploadPostImage extends ProfileEvent {
  final String userId;
  final XFile imageFile;
  const UploadPostImage(this.userId, this.imageFile);

  @override
  List<Object> get props => [userId, imageFile];
}
