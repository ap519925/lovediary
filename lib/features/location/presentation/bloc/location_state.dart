part of 'location_bloc.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationGranted extends LocationState {
  final Position position;

  const LocationGranted(this.position);

  @override
  List<Object?> get props => [position];
}

class LocationReceived extends LocationState {
  final Position position;

  const LocationReceived(this.position);

  @override
  List<Object?> get props => [position];
}

class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}