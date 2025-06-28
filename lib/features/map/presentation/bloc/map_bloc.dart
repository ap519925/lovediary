import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovediary/features/map/data/location_service.dart';

import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final FirebaseFirestore firestore;
  final String userId;
  final String partnerId;
  StreamSubscription? _locationSubscription;

  MapBloc({
    required this.firestore,
    required this.userId,
    required this.partnerId,
  }) : super(MapInitial()) {
    on<LoadUserLocations>(_onLoadUserLocations);
    on<LoadCurrentLocation>(_onLoadCurrentLocation);
    on<UpdateCurrentLocation>(_onUpdateCurrentLocation);
    on<UpdateLocation>(_onUpdateLocation);
  }

  Future<void> _onLoadCurrentLocation(
    LoadCurrentLocation event,
    Emitter<MapState> emit,
  ) async {
    if (isClosed) return; // Prevent events after bloc is closed
    
    emit(MapLoading());
    try {
      final position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);
      
      // Start listening to location updates with throttling
      _locationSubscription?.cancel(); // Cancel any existing subscription
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Only update when moved 10 meters
        ),
      ).listen((position) {
        if (!isClosed) { // Check if bloc is still active before adding events
          add(UpdateLocation(LatLng(position.latitude, position.longitude)));
        }
      });

      // Get partner location from Firestore
      final partnerLocation = await _getPartnerLocation();
      
      // Get location information
      final currentLocationInfo = await LocationService.getLocationInfo(currentLocation);
      LocationInfo? partnerLocationInfo;
      double? distance;
      
      if (partnerLocation != null) {
        partnerLocationInfo = await LocationService.getLocationInfo(partnerLocation);
        distance = LocationService.calculateDistance(currentLocation, partnerLocation);
      }
      
      if (!isClosed) { // Check before emitting
        emit(MapLoaded(
          currentLocation, 
          partnerLocation,
          currentLocationInfo: currentLocationInfo,
          partnerLocationInfo: partnerLocationInfo,
          distance: distance,
        ));
      }
    } catch (e) {
      if (!isClosed) { // Check before emitting
        emit(MapError('Failed to load locations: ${e.toString()}'));
      }
    }
  }

  Future<void> _onLoadUserLocations(
    LoadUserLocations event,
    Emitter<MapState> emit,
  ) async {
    add(LoadCurrentLocation());
  }

  Future<void> _onUpdateCurrentLocation(
    UpdateCurrentLocation event,
    Emitter<MapState> emit,
  ) async {
    add(LoadCurrentLocation());
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<MapState> emit,
  ) async {
    if (isClosed) return; // Prevent events after bloc is closed
    
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      
      // Only update if location has changed significantly (more than 10 meters)
      final previousLocation = currentState.currentLocation;
      final distance = LocationService.calculateDistance(
        previousLocation, 
        event.location
      );
      
      if (distance < 0.01) { // Less than 10 meters, don't update
        return;
      }
      
      // Reuse partner location and info from current state to avoid redundant calls
      final partnerLocation = currentState.partnerLocation;
      final partnerLocationInfo = currentState.partnerLocationInfo;
      
      // Only recalculate distance if we have partner location
      double? newDistance;
      if (partnerLocation != null) {
        newDistance = LocationService.calculateDistance(event.location, partnerLocation);
      }
      
      // Get location info only for the new user location
      final currentLocationInfo = await LocationService.getLocationInfo(event.location);
      
      emit(MapLoaded(
        event.location, 
        partnerLocation,
        currentLocationInfo: currentLocationInfo,
        partnerLocationInfo: partnerLocationInfo,
        distance: newDistance,
      ));
    }
  }

  Future<LatLng?> _getPartnerLocation() async {
    try {
      final partnerDoc = await firestore.collection('users').doc(partnerId).get();
      final partnerData = partnerDoc.data();
      if (partnerData != null && partnerData['location'] != null) {
        return LatLng(
          partnerData['location']['latitude'],
          partnerData['location']['longitude'],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
