part of 'map_bloc.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  const MapLoaded(
    this.currentLocation, 
    this.partnerLocation, {
    this.currentLocationInfo,
    this.partnerLocationInfo,
    this.distance,
  });
  
  final LatLng currentLocation;
  final LatLng? partnerLocation;
  final LocationInfo? currentLocationInfo;
  final LocationInfo? partnerLocationInfo;
  final double? distance;

  @override
  List<Object> get props => [
    currentLocation, 
    partnerLocation ?? '', 
    currentLocationInfo ?? '',
    partnerLocationInfo ?? '',
    distance ?? 0.0,
  ];
  
  MapLoaded copyWith({
    LatLng? currentLocation,
    LatLng? partnerLocation,
    LocationInfo? currentLocationInfo,
    LocationInfo? partnerLocationInfo,
    double? distance,
  }) {
    return MapLoaded(
      currentLocation ?? this.currentLocation,
      partnerLocation ?? this.partnerLocation,
      currentLocationInfo: currentLocationInfo ?? this.currentLocationInfo,
      partnerLocationInfo: partnerLocationInfo ?? this.partnerLocationInfo,
      distance: distance ?? this.distance,
    );
  }
}

class MapError extends MapState {
  const MapError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
