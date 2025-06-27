import 'package:flutter/material.dart';
import 'package:lovediary/core/services/location_service.dart';
import 'package:lovediary/core/services/storage_service.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  // Singleton instance
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();

  /// Check if all required permissions are granted
  Future<Map<String, bool>> checkAllPermissions() async {
    try {
      final results = <String, bool>{};
      
      // Check location permissions
      final locationPermission = await _locationService.checkPermission();
      results['location'] = locationPermission == LocationPermission.whileInUse ||
                           locationPermission == LocationPermission.always;
      
      // Check storage permissions
      results['storage'] = await _storageService.hasStoragePermissions();
      
      // Check camera permission
      results['camera'] = await _storageService.hasCameraPermission();
      
      debugPrint('Permission status check: $results');
      return results;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return {
        'location': false,
        'storage': false,
        'camera': false,
      };
    }
  }

  /// Request all required permissions
  Future<Map<String, bool>> requestAllPermissions() async {
    try {
      final results = <String, bool>{};
      
      debugPrint('=== REQUESTING ALL PERMISSIONS ===');
      
      // Request location permissions first
      debugPrint('Requesting location permissions...');
      final locationPermission = await _locationService.requestPermission();
      results['location'] = locationPermission == LocationPermission.whileInUse ||
                           locationPermission == LocationPermission.always;
      debugPrint('Location permission result: ${results['location']}');
      
      // Request storage permissions
      debugPrint('Requesting storage permissions...');
      results['storage'] = await _storageService.requestStoragePermissions();
      debugPrint('Storage permission result: ${results['storage']}');
      
      // Request camera permission
      debugPrint('Requesting camera permissions...');
      results['camera'] = await _storageService.requestCameraPermission();
      debugPrint('Camera permission result: ${results['camera']}');
      
      debugPrint('=== PERMISSION REQUEST RESULTS ===');
      debugPrint('Final results: $results');
      
      return results;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return {
        'location': false,
        'storage': false,
        'camera': false,
      };
    }
  }

  /// Request location permissions only
  Future<bool> requestLocationPermissions() async {
    try {
      debugPrint('Requesting location permissions only...');
      final permission = await _locationService.requestPermission();
      final granted = permission == LocationPermission.whileInUse ||
                     permission == LocationPermission.always;
      debugPrint('Location permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('Error requesting location permissions: $e');
      return false;
    }
  }

  /// Request storage permissions only
  Future<bool> requestStoragePermissions() async {
    try {
      debugPrint('Requesting storage permissions only...');
      final granted = await _storageService.requestStoragePermissions();
      debugPrint('Storage permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('Error requesting storage permissions: $e');
      return false;
    }
  }

  /// Request camera permissions only
  Future<bool> requestCameraPermissions() async {
    try {
      debugPrint('Requesting camera permissions only...');
      final granted = await _storageService.requestCameraPermission();
      debugPrint('Camera permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('Error requesting camera permissions: $e');
      return false;
    }
  }

  /// Check if any permissions are permanently denied
  Future<Map<String, bool>> checkPermanentlyDeniedPermissions() async {
    try {
      final results = <String, bool>{};
      
      // Check location permission
      final locationPermission = await _locationService.checkPermission();
      results['location'] = locationPermission == LocationPermission.deniedForever;
      
      // Check storage permission
      results['storage'] = await _storageService.isStoragePermissionPermanentlyDenied();
      
      // Camera permission - check if permanently denied
      // Note: permission_handler doesn't have a direct way to check this for camera
      // so we'll assume false for now
      results['camera'] = false;
      
      return results;
    } catch (e) {
      debugPrint('Error checking permanently denied permissions: $e');
      return {
        'location': false,
        'storage': false,
        'camera': false,
      };
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await _storageService.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Get permission status descriptions
  Future<Map<String, String>> getPermissionStatusDescriptions() async {
    try {
      final results = <String, String>{};
      
      // Location permission description
      final locationPermission = await _locationService.checkPermission();
      switch (locationPermission) {
        case LocationPermission.always:
          results['location'] = 'Location access granted (always)';
          break;
        case LocationPermission.whileInUse:
          results['location'] = 'Location access granted (while in use)';
          break;
        case LocationPermission.denied:
          results['location'] = 'Location access denied';
          break;
        case LocationPermission.deniedForever:
          results['location'] = 'Location access permanently denied';
          break;
        case LocationPermission.unableToDetermine:
          results['location'] = 'Unable to determine location permission';
          break;
      }
      
      // Storage permission description
      results['storage'] = await _storageService.getStoragePermissionStatusDescription();
      
      // Camera permission description
      final cameraGranted = await _storageService.hasCameraPermission();
      results['camera'] = cameraGranted ? 'Camera access granted' : 'Camera access denied';
      
      return results;
    } catch (e) {
      debugPrint('Error getting permission descriptions: $e');
      return {
        'location': 'Error checking location permission',
        'storage': 'Error checking storage permission',
        'camera': 'Error checking camera permission',
      };
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await _locationService.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await _locationService.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
      return false;
    }
  }

  /// Get current location (if permissions are granted)
  Future<Position?> getCurrentLocation() async {
    try {
      return await _locationService.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Request background location permission
  Future<bool> requestBackgroundLocationPermission() async {
    try {
      return await _locationService.requestBackgroundPermission();
    } catch (e) {
      debugPrint('Error requesting background location permission: $e');
      return false;
    }
  }
}
