import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lovediary/features/map/presentation/bloc/map_bloc.dart';
import 'package:lovediary/features/map/presentation/bloc/map_event.dart';
import 'package:lovediary/features/map/presentation/bloc/map_state.dart';
import 'package:lovediary/l10n/app_localizations.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  
  // Default location (San Francisco)
  static const LatLng _defaultLocation = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    // Load user locations when screen initializes
    context.read<MapBloc>().add(LoadUserLocations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.map ?? 'Map'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              context.read<MapBloc>().add(UpdateCurrentLocation());
            },
            tooltip: 'Update Location',
          ),
        ],
      ),
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is MapError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading map',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MapBloc>().add(LoadUserLocations());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is MapLoaded) {
            return _buildMap(state);
          }
          
          // Default state - show map with default location
          return _buildDefaultMap();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showLocationInfo(context);
        },
        backgroundColor: Colors.pink,
        child: const Icon(Icons.info, color: Colors.white),
      ),
    );
  }

  Widget _buildMap(MapLoaded state) {
    final Set<Marker> markers = {};
    
    // Add user marker
    if (state.userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: state.userLocation!,
          infoWindow: InfoWindow(
            title: 'You',
            snippet: state.userLocationName ?? 'Your location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Add partner marker
    if (state.partnerLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('partner'),
          position: state.partnerLocation!,
          infoWindow: InfoWindow(
            title: 'Partner',
            snippet: state.partnerLocationName ?? 'Partner location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    
    // Calculate camera position
    LatLng cameraTarget = _defaultLocation;
    double zoom = 10.0;
    
    if (state.userLocation != null && state.partnerLocation != null) {
      // Show both locations
      cameraTarget = LatLng(
        (state.userLocation!.latitude + state.partnerLocation!.latitude) / 2,
        (state.userLocation!.longitude + state.partnerLocation!.longitude) / 2,
      );
      zoom = 8.0;
    } else if (state.userLocation != null) {
      cameraTarget = state.userLocation!;
    } else if (state.partnerLocation != null) {
      cameraTarget = state.partnerLocation!;
    }

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: cameraTarget,
        zoom: zoom,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildDefaultMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      initialCameraPosition: const CameraPosition(
        target: _defaultLocation,
        zoom: 10.0,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  void _showLocationInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapLoaded) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (state.userLocation != null) ...[
                    _buildLocationCard(
                      'Your Location',
                      state.userLocationName ?? 'Unknown',
                      state.userLocation!,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.partnerLocation != null) ...[
                    _buildLocationCard(
                      'Partner Location',
                      state.partnerLocationName ?? 'Unknown',
                      state.partnerLocation!,
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.distance != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.straighten, color: Colors.pink[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Distance: ${state.distance!.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.pink[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (state.userLocation == null && state.partnerLocation == null) ...[
                    const Text(
                      'No location data available. Make sure location permissions are granted and try updating your location.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            );
          }
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text('Loading location information...'),
          );
        },
      ),
    );
  }

  Widget _buildLocationCard(String title, String address, LatLng location, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(address),
          const SizedBox(height: 4),
          Text(
            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
