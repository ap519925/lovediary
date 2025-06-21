part of 'map_bloc.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final LatLng currentLocation;
  final LatLng? partnerLocation;

  const MapLoaded(this.currentLocation, this.partnerLocation);

  @override
  List<Object> get props => [currentLocation, partnerLocation ?? ''];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object> get props => [message];
}
