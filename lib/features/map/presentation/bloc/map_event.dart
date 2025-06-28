import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class LoadUserLocations extends MapEvent {
  const LoadUserLocations();
}

class LoadCurrentLocation extends MapEvent {
  const LoadCurrentLocation();
}

class UpdateCurrentLocation extends MapEvent {
  const UpdateCurrentLocation();
}

class UpdateLocation extends MapEvent {
  final LatLng location;
  
  const UpdateLocation(this.location);
  
  @override
  List<Object> get props => [location];
}

class UpdatePartnerLocation extends MapEvent {
  const UpdatePartnerLocation();
}

class UpdatePartnerId extends MapEvent {
  final String partnerId;
  
  const UpdatePartnerId(this.partnerId);
  
  @override
  List<Object> get props => [partnerId];
}

class CalculateDistance extends MapEvent {
  const CalculateDistance();
}
