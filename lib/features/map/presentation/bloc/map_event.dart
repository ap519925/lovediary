part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class LoadCurrentLocation extends MapEvent {}

class UpdateLocation extends MapEvent {

  const UpdateLocation(this.location);
  final LatLng location;

  @override
  List<Object> get props => [location];
}
