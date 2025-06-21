import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'map_event.dart';
part 'map_state.dart';

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
    on<LoadCurrentLocation>(_onLoadCurrentLocation);
    on<UpdateLocation>(_onUpdateLocation);
  }

  Future<void> _onLoadCurrentLocation(
    LoadCurrentLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());
    try {
      final position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);
      
      // Start listening to location updates
      _locationSubscription = Geolocator.getPositionStream().listen((position) {
        add(UpdateLocation(LatLng(position.latitude, position.longitude)));
      });

      // Get partner location from Firestore
      final partnerLocation = await _getPartnerLocation();
      emit(MapLoaded(currentLocation, partnerLocation));
    } catch (e) {
      emit(MapError('Failed to load locations: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      final partnerLocation = await _getPartnerLocation();
      emit(MapLoaded(event.location, partnerLocation));
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
