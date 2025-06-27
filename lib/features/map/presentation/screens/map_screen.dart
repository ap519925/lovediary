import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lovediary/features/map/presentation/bloc/map_bloc.dart';
import 'package:lovediary/features/map/presentation/widgets/custom_marker.dart';
import 'package:lovediary/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  bool _isMapReady = false;
  BitmapDescriptor? _userMarker;
  BitmapDescriptor? _partnerMarker;
  BitmapDescriptor? _heartMarker;

  @override
  void initState() {
    super.initState();
    _initMarkers();
    _requestLocationPermission();
  }
  
  Future<void> _initMarkers() async {
    try {
      // Create custom markers
      _userMarker = await CustomMarker.createCustomMarkerWithInitials(
        'ME',
        backgroundColor: Colors.blue,
        size: 80,
      );
      
      _partnerMarker = await CustomMarker.createCustomMarkerWithInitials(
        'LP',
        backgroundColor: Colors.red,
        size: 80,
      );
      
      // Create heart marker with larger size and brighter color
      _heartMarker = await CustomMarker.createHeartMarker(
        color: Colors.pink.shade400,
        size: 100,
      );
      
      print('Custom markers created successfully:');
      print('- User marker: ${_userMarker != null ? 'OK' : 'Failed'}');
      print('- Partner marker: ${_partnerMarker != null ? 'OK' : 'Failed'}');
      print('- Heart marker: ${_heartMarker != null ? 'OK' : 'Failed'}');
      
      // Force a rebuild if the widget is mounted
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error creating custom markers: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      // For web, skip permission request as it's handled by the browser
      if (kIsWeb) {
        context.read<MapBloc>().add(LoadCurrentLocation());
        return;
      }

      // Use the existing LocationService for consistent permission handling
      final locationService = LocationService();
      
      // Check if location services are enabled first
      final serviceEnabled = await locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are disabled. Please enable them in settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => locationService.openLocationSettings(),
              ),
            ),
          );
        }
        return;
      }

      // Check current permission status
      final permission = await locationService.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        final newPermission = await locationService.requestPermission();
        if (newPermission == LocationPermission.whileInUse || 
            newPermission == LocationPermission.always) {
          // Permission granted, load location
          context.read<MapBloc>().add(LoadCurrentLocation());
        } else {
          // Permission denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to show your location on the map.'),
              ),
            );
          }
        }
      } else if (permission == LocationPermission.deniedForever) {
        // Permission permanently denied
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission is permanently denied. Please enable it in app settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      } else if (permission == LocationPermission.whileInUse || 
                 permission == LocationPermission.always) {
        // Permission already granted
        context.read<MapBloc>().add(LoadCurrentLocation());
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error requesting location permission. Please try again.'),
          ),
        );
      }
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
            // Use a Future.microtask to handle the async _updateMap method
            Future.microtask(() => _updateMap(state));
          }
        },
        builder: (context, state) {
          if (state is MapLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is MapError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<MapBloc>().add(LoadCurrentLocation()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is MapLoaded) {
            return Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: state.currentLocation,
                      zoom: 15,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    circles: _circles,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      setState(() {
                        _isMapReady = true;
                      });
                    },
                    myLocationEnabled: false, // We'll use custom markers instead
                    myLocationButtonEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                  ),
                ),
                _buildLocationInfo(state),
              ],
            );
          }
          
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Tap refresh to load location data'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateMap(MapLoaded state) async {
    // Only update the map if the controller is initialized
    if (_mapController == null || !_isMapReady) {
      // Store the state to update the map once it's ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController != null && _isMapReady) {
          _updateMap(state);
        }
      });
      return;
    }
    
    setState(() {
      _markers.clear();
      _polylines.clear();
      _circles.clear();

      // Add current location marker
      _markers.add(Marker(
        markerId: const MarkerId('current_location'),
        position: state.currentLocation,
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: state.currentLocationInfo?.city ?? 'Unknown location',
        ),
        icon: _userMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
      
      // Add a circle around current location
      _circles.add(Circle(
        circleId: const CircleId('current_location_radius'),
        center: state.currentLocation,
        radius: 100, // 100 meters radius
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue.withOpacity(0.5),
        strokeWidth: 1,
      ));

      // Add partner location marker if available
      if (state.partnerLocation != null) {
        _markers.add(Marker(
          markerId: const MarkerId('partner_location'),
          position: state.partnerLocation!,
          infoWindow: InfoWindow(
            title: 'Partner Location',
            snippet: state.partnerLocationInfo?.city ?? 'Unknown location',
          ),
          icon: _partnerMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
        
        // Add a circle around partner location
        _circles.add(Circle(
          circleId: const CircleId('partner_location_radius'),
          center: state.partnerLocation!,
          radius: 100, // 100 meters radius
          fillColor: Colors.red.withOpacity(0.2),
          strokeColor: Colors.red.withOpacity(0.5),
          strokeWidth: 1,
        ));

        // Add polyline between locations
        _polylines.add(Polyline(
          polylineId: const PolylineId('connection_line'),
          points: [state.currentLocation, state.partnerLocation!],
          color: Colors.pink,
          width: 3,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ));
        
        // Add heart marker at the midpoint with slight offset for better visibility
        final midLat = (state.currentLocation.latitude + state.partnerLocation!.latitude) / 2;
        final midLng = (state.currentLocation.longitude + state.partnerLocation!.longitude) / 2;
        
        // Add the heart marker
        _markers.add(Marker(
          markerId: const MarkerId('heart_marker'),
          position: LatLng(midLat, midLng),
          icon: _heartMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(
            title: 'Distance',
            snippet: state.distance != null 
                ? '${state.distance!.toStringAsFixed(1)} km apart'
                : 'Calculating...',
          ),
          zIndex: 2, // Make sure heart appears above other markers
        ));
      }
    });

    // Move camera to show both locations
    try {
      if (state.partnerLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                math.min(state.currentLocation.latitude, state.partnerLocation!.latitude) - 0.01,
                math.min(state.currentLocation.longitude, state.partnerLocation!.longitude) - 0.01,
              ),
              northeast: LatLng(
                math.max(state.currentLocation.latitude, state.partnerLocation!.latitude) + 0.01,
                math.max(state.currentLocation.longitude, state.partnerLocation!.longitude) + 0.01,
              ),
            ),
            100,
          ),
        );
      } else {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(state.currentLocation, 15),
        );
      }
    } catch (e) {
      print('Error animating camera: $e');
    }
  }

  void _addMarker(LatLng position) {
    final markerId = MarkerId(position.toString());
    final marker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: InfoWindow(
        title: 'Marker',
        snippet: 'Lat: ${position.latitude}, Lng: ${position.longitude}',
      ),
    );
    setState(() {
      _markers.add(marker);
    });
  }

  void _addPolyline(List<LatLng> points) {
    final polylineId = PolylineId(math.Random().nextInt(10000).toString());
    final polyline = Polyline(
      polylineId: polylineId,
      points: points,
      color: Colors.blue,
      width: 5,
    );
    setState(() {
      _polylines.add(polyline);
    });
  }

  Widget _buildLocationInfo(MapLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Your Location',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Latitude: ${state.currentLocation.latitude.toStringAsFixed(6)}'),
                  Text('Longitude: ${state.currentLocation.longitude.toStringAsFixed(6)}'),
                  if (state.currentLocationInfo != null) ...[
                    const Divider(),
                    Row(
                      children: [
                        Icon(Icons.location_city, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.currentLocationInfo!.city,
                            style: Theme.of(context).textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.flag, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.currentLocationInfo!.country,
                            style: Theme.of(context).textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.partnerLocation != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Partner Location',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Latitude: ${state.partnerLocation!.latitude.toStringAsFixed(6)}'),
                    Text('Longitude: ${state.partnerLocation!.longitude.toStringAsFixed(6)}'),
                    if (state.partnerLocationInfo != null) ...[
                      const Divider(),
                      Row(
                        children: [
                          Icon(Icons.location_city, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.partnerLocationInfo!.city,
                              style: Theme.of(context).textTheme.bodyLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.flag, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.partnerLocationInfo!.country,
                              style: Theme.of(context).textTheme.bodyLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.pink.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.straighten, color: Colors.pink),
                        const SizedBox(width: 8),
                        Text(
                          'Distance',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.distance != null
                          ? '${state.distance!.toStringAsFixed(2)} km'
                          : 'Calculating...',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (state.currentLocationInfo != null && state.partnerLocationInfo != null) ...[
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You are in:',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  state.currentLocationInfo!.city,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward, color: Colors.pink),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Partner is in:',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.right,
                                ),
                                Text(
                                  state.partnerLocationInfo!.city,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Partner Location',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Partner location not available'),
                    const Text('Make sure your partner has shared their location'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Maps feature requires Google Maps API configuration',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Location data is displayed above',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }
}
