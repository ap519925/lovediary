part of 'location_bloc.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class RequestLocationPermission extends LocationEvent {
  final bool requestBackground;

  const RequestLocationPermission({
    this.requestBackground = false,
  });

  @override
  List<Object?> get props => [requestBackground];
}

class StartLocationUpdates extends LocationEvent {
  final LocationAccuracy accuracy;
  final int distanceFilter;

  const StartLocationUpdates({
    this.accuracy = LocationAccuracy.high,
    this.distanceFilter = 10,
  });

  @override
  List<Object?> get props => [accuracy, distanceFilter];
}

class StopLocationUpdates extends LocationEvent {
  const StopLocationUpdates();
}

class LocationUpdated extends LocationEvent {
  final Position position;

  const LocationUpdated(this.position);

  @override
  List<Object?> get props => [position];
}