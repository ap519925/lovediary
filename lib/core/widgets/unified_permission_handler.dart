import 'package:flutter/material.dart';
import 'package:lovediary/core/services/permission_service.dart';
import 'package:geolocator/geolocator.dart';

class UnifiedPermissionHandler extends StatefulWidget {
  final Widget child;
  final Function(Position)? onLocationGranted;
  final Function()? onStorageGranted;
  final Function()? onCameraGranted;
  final Function(Map<String, bool>)? onAllPermissionsGranted;
  final bool requestLocation;
  final bool requestStorage;
  final bool requestCamera;
  final bool requestBackground;
  final bool showLoadingOverlay;

  const UnifiedPermissionHandler({
    super.key,
    required this.child,
    this.onLocationGranted,
    this.onStorageGranted,
    this.onCameraGranted,
    this.onAllPermissionsGranted,
    this.requestLocation = false,
    this.requestStorage = false,
    this.requestCamera = false,
    this.requestBackground = false,
    this.showLoadingOverlay = true,
  });

  @override
  State<UnifiedPermissionHandler> createState() => _UnifiedPermissionHandlerState();
}

class _UnifiedPermissionHandlerState extends State<UnifiedPermissionHandler> {
  final PermissionService _permissionService = PermissionService();
  bool _isCheckingPermissions = false;
  Map<String, bool> _permissionResults = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (_isCheckingPermissions) return;
    setState(() => _isCheckingPermissions = true);

    try {
      debugPrint('=== CHECKING PERMISSIONS ===');
      debugPrint('Request location: ${widget.requestLocation}');
      debugPrint('Request storage: ${widget.requestStorage}');
      debugPrint('Request camera: ${widget.requestCamera}');

      // Check current permission status
      final currentStatus = await _permissionService.checkAllPermissions();
      debugPrint('Current permission status: $currentStatus');

      final results = <String, bool>{};
      bool needsToRequest = false;

      // Check location permission
      if (widget.requestLocation) {
        if (currentStatus['location'] == true) {
          results['location'] = true;
          debugPrint('Location permission already granted');
        } else {
          needsToRequest = true;
          debugPrint('Location permission needed');
        }
      }

      // Check storage permission
      if (widget.requestStorage) {
        if (currentStatus['storage'] == true) {
          results['storage'] = true;
          debugPrint('Storage permission already granted');
        } else {
          needsToRequest = true;
          debugPrint('Storage permission needed');
        }
      }

      // Check camera permission
      if (widget.requestCamera) {
        if (currentStatus['camera'] == true) {
          results['camera'] = true;
          debugPrint('Camera permission already granted');
        } else {
          needsToRequest = true;
          debugPrint('Camera permission needed');
        }
      }

      if (needsToRequest) {
        debugPrint('Requesting missing permissions...');
        await _requestMissingPermissions(currentStatus);
      } else {
        debugPrint('All required permissions already granted');
        _handlePermissionResults(results);
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      _showErrorDialog('Permission Check Error', 'Failed to check permissions: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingPermissions = false);
      }
    }
  }

  Future<void> _requestMissingPermissions(Map<String, bool> currentStatus) async {
    try {
      final results = <String, bool>{};

      // Request location permission if needed
      if (widget.requestLocation && currentStatus['location'] != true) {
        debugPrint('Requesting location permission...');
        
        // Check if location services are enabled first
        final serviceEnabled = await _permissionService.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            _showLocationServiceDialog();
            return;
          }
        }

        final granted = await _permissionService.requestLocationPermissions();
        results['location'] = granted;
        debugPrint('Location permission result: $granted');

        if (granted && widget.requestBackground) {
          debugPrint('Requesting background location permission...');
          final backgroundGranted = await _permissionService.requestBackgroundLocationPermission();
          debugPrint('Background location permission result: $backgroundGranted');
        }
      } else {
        results['location'] = currentStatus['location'] ?? false;
      }

      // Request storage permission if needed
      if (widget.requestStorage && currentStatus['storage'] != true) {
        debugPrint('Requesting storage permission...');
        final granted = await _permissionService.requestStoragePermissions();
        results['storage'] = granted;
        debugPrint('Storage permission result: $granted');
      } else {
        results['storage'] = currentStatus['storage'] ?? false;
      }

      // Request camera permission if needed
      if (widget.requestCamera && currentStatus['camera'] != true) {
        debugPrint('Requesting camera permission...');
        final granted = await _permissionService.requestCameraPermissions();
        results['camera'] = granted;
        debugPrint('Camera permission result: $granted');
      } else {
        results['camera'] = currentStatus['camera'] ?? false;
      }

      debugPrint('Final permission results: $results');
      _handlePermissionResults(results);
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      _showErrorDialog('Permission Request Error', 'Failed to request permissions: $e');
    }
  }

  void _handlePermissionResults(Map<String, bool> results) {
    _permissionResults = results;

    // Handle location permission callback
    if (widget.requestLocation && results['location'] == true && widget.onLocationGranted != null) {
      _permissionService.getCurrentLocation().then((position) {
        if (position != null && mounted) {
          widget.onLocationGranted!(position);
        }
      }).catchError((e) {
        debugPrint('Error getting current location: $e');
      });
    }

    // Handle storage permission callback
    if (widget.requestStorage && results['storage'] == true && widget.onStorageGranted != null) {
      widget.onStorageGranted!();
    }

    // Handle camera permission callback
    if (widget.requestCamera && results['camera'] == true && widget.onCameraGranted != null) {
      widget.onCameraGranted!();
    }

    // Handle all permissions callback
    if (widget.onAllPermissionsGranted != null) {
      widget.onAllPermissionsGranted!(results);
    }

    // Check for permanently denied permissions
    _checkPermanentlyDeniedPermissions();
  }

  Future<void> _checkPermanentlyDeniedPermissions() async {
    try {
      final permanentlyDenied = await _permissionService.checkPermanentlyDeniedPermissions();
      
      final deniedPermissions = <String>[];
      if (widget.requestLocation && permanentlyDenied['location'] == true) {
        deniedPermissions.add('Location');
      }
      if (widget.requestStorage && permanentlyDenied['storage'] == true) {
        deniedPermissions.add('Storage');
      }
      if (widget.requestCamera && permanentlyDenied['camera'] == true) {
        deniedPermissions.add('Camera');
      }

      if (deniedPermissions.isNotEmpty && mounted) {
        _showPermanentlyDeniedDialog(deniedPermissions);
      }
    } catch (e) {
      debugPrint('Error checking permanently denied permissions: $e');
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled on your device. Please enable them in your device settings to use location features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openLocationSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog(List<String> permissions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Text(
          'The following permissions have been permanently denied: ${permissions.join(', ')}. '
          'Please enable them in app settings to use these features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openAppSettings();
            },
            child: const Text('App Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPermissions(); // Retry
            },
            child: const Text('Retry'),
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
        if (_isCheckingPermissions && widget.showLoadingOverlay)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Checking permissions...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
