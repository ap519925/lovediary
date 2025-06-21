import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lovediary/features/map/presentation/bloc/map_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<MapBloc>().add(LoadCurrentLocation());
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MapBloc>().add(LoadCurrentLocation()),
          ),
        ],
      ),
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) {
          if (state is MapLoaded) {
            _updateMap(state);
          }
        },
        builder: (context, state) {
          if (state is MapLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 2,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
    );
  }

  void _updateMap(MapLoaded state) {
    _markers.clear();
    _polylines.clear();

    // Add current location marker
    _markers.add(Marker(
      markerId: const MarkerId('current_location'),
      position: state.currentLocation,
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));

    // Add partner location marker if available
    if (state.partnerLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('partner_location'),
        position: state.partnerLocation!,
        infoWindow: const InfoWindow(title: 'Partner Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));

      // Add polyline between locations
      _polylines.add(Polyline(
        polylineId: const PolylineId('connection_line'),
        points: [state.currentLocation, state.partnerLocation!],
        color: Colors.pink,
        width: 3,
      ));

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        state.currentLocation.latitude,
        state.currentLocation.longitude,
        state.partnerLocation!.latitude,
        state.partnerLocation!.longitude,
      ).round();

      // Show distance info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Distance between you: ${distance}m'),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    // Move camera to show both locations
    if (state.partnerLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              math.min(state.currentLocation.latitude, state.partnerLocation!.latitude),
              math.min(state.currentLocation.longitude, state.partnerLocation!.longitude),
            ),
            northeast: LatLng(
              math.max(state.currentLocation.latitude, state.partnerLocation!.latitude),
              math.max(state.currentLocation.longitude, state.partnerLocation!.longitude),
            ),
          ),
          100,
        ),
      );
    } else {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(state.currentLocation, 15),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
