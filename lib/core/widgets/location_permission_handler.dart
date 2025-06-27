import 'package:flutter/material.dart';
import 'package:lovediary/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionHandler extends StatefulWidget {
  final Widget child;
  final Function(Position) onLocationGranted;
  final bool requestBackground;

  const LocationPermissionHandler({
    super.key,
    required this.child,
    required this.onLocationGranted,
    this.requestBackground = false,
  });

  @override
  State<LocationPermissionHandler> createState() => _LocationPermissionHandlerState();
}

class _LocationPermissionHandlerState extends State<LocationPermissionHandler> {
  final LocationService _locationService = LocationService();
  bool _isCheckingPermission = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    if (_isCheckingPermission) return;
    setState(() => _isCheckingPermission = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showLocationDialog(
          'Location services are disabled',
          'Please enable location services to use this feature.',
          () => _locationService.openLocationSettings(),
        );
        return;
      }

      // Check permission status
      LocationPermission permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          _showLocationDialog(
            'Location permission denied',
            'Please grant location permission to use this feature.',
            () => _locationService.requestPermission(),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showLocationDialog(
          'Location permission permanently denied',
          'Please enable location permission in app settings.',
          () => _locationService.openAppSettings(),
        );
        return;
      }

      // Request background permission if needed
      if (widget.requestBackground) {
        bool backgroundGranted = await _locationService.requestBackgroundPermission();
        if (!backgroundGranted) {
          if (!mounted) return;
          _showLocationDialog(
            'Background location access required',
            'Please allow background location access in app settings.',
            () => _locationService.openAppSettings(),
          );
          return;
        }
      }

      // Get current position
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        widget.onLocationGranted(position);
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingPermission = false);
      }
    }
  }

  void _showLocationDialog(String title, String message, Function() onAction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isCheckingPermission)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}