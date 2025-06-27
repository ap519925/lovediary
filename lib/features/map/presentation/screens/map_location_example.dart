import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lovediary/features/location/presentation/bloc/location_bloc.dart';

class MapLocationExample extends StatefulWidget {
  const MapLocationExample({super.key});

  @override
  State<MapLocationExample> createState() => _MapLocationExampleState();
}

class _MapLocationExampleState extends State<MapLocationExample> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  void _requestLocationPermission() {
    setState(() => _isLoading = true);
    context.read<LocationBloc>().add(
          const RequestLocationPermission(requestBackground: false),
        );
  }

  void _startLocationUpdates() {
    context.read<LocationBloc>().add(
          const StartLocationUpdates(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        );
  }

  void _stopLocationUpdates() {
    context.read<LocationBloc>().add(const StopLocationUpdates());
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapWithCurrentLocation();
  }

  void _updateMapWithCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      final latLng = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: latLng,
            zoom: 15,
          ),
        ),
      );

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: latLng,
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Example'),
      ),
      body: BlocConsumer<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationGranted || state is LocationReceived) {
            setState(() => _isLoading = false);
            
            final position = state is LocationGranted 
                ? state.position 
                : (state as LocationReceived).position;
            
            setState(() => _currentPosition = position);
            _updateMapWithCurrentLocation();
            
            // Start location updates after permission is granted
            if (state is LocationGranted) {
              _startLocationUpdates();
            }
          } else if (state is LocationError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LocationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _requestLocationPermission,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 2,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _markers,
              ),
              if (_currentPosition != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(2)} meters',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}