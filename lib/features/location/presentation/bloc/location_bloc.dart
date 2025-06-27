import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lovediary/core/services/location_service.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationService _locationService;
  StreamSubscription<Position>? _locationSubscription;

  LocationBloc({LocationService? locationService})
      : _locationService = locationService ?? LocationService(),
        super(LocationInitial()) {
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<StartLocationUpdates>(_onStartLocationUpdates);
    on<StopLocationUpdates>(_onStopLocationUpdates);
    on<LocationUpdated>(_onLocationUpdated);
  }

  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    try {
      // Check if location services are enabled
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationError('Location services are disabled'));
        return;
      }

      // Check permission status
      LocationPermission permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(const LocationError('Location permission denied'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(const LocationError(
            'Location permissions are permanently denied'));
        return;
      }

      // Request background permission if needed
      if (event.requestBackground) {
        bool backgroundGranted =
            await _locationService.requestBackgroundPermission();
        if (!backgroundGranted) {
          emit(const LocationError(
              'Background location permission denied'));
          return;
        }
      }

      // Get current position
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        emit(LocationGranted(position));
      } else {
        emit(const LocationError('Failed to get current location'));
      }
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  Future<void> _onStartLocationUpdates(
    StartLocationUpdates event,
    Emitter<LocationState> emit,
  ) async {
    try {
      _locationSubscription?.cancel();
      _locationSubscription = _locationService
          .getPositionStream(
            accuracy: event.accuracy,
            distanceFilter: event.distanceFilter,
          )
          .listen(
            (position) => add(LocationUpdated(position)),
          );
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  Future<void> _onStopLocationUpdates(
    StopLocationUpdates event,
    Emitter<LocationState> emit,
  ) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _onLocationUpdated(
    LocationUpdated event,
    Emitter<LocationState> emit,
  ) {
    emit(LocationReceived(event.position));
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}