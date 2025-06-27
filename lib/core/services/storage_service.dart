import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class StorageService {
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Check if storage permissions are granted
  Future<bool> hasStoragePermissions() async {
    if (kIsWeb) {
      // Web doesn't need explicit storage permissions
      return true;
    }

    if (Platform.isIOS) {
      // iOS uses photo library permission
      final status = await Permission.photos.status;
      return status.isGranted;
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+ uses granular media permissions
        final images = await Permission.photos.status;
        final videos = await Permission.videos.status;
        return images.isGranted && videos.isGranted;
      } else if (sdkInt >= 30) {
        // Android 11-12 uses scoped storage
        final storage = await Permission.storage.status;
        return storage.isGranted;
      } else {
        // Android 10 and below
        final storage = await Permission.storage.status;
        return storage.isGranted;
      }
    }

    return false;
  }

  /// Request storage permissions
  Future<bool> requestStoragePermissions() async {
    try {
      if (kIsWeb) {
        // Web doesn't need explicit storage permissions
        return true;
      }

      if (Platform.isIOS) {
        // iOS photo library permission
        final status = await Permission.photos.request();
        return status.isGranted;
      }

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+ granular media permissions
          final Map<Permission, PermissionStatus> statuses = await [
            Permission.photos,
            Permission.videos,
          ].request();

          return statuses[Permission.photos]?.isGranted == true &&
                 statuses[Permission.videos]?.isGranted == true;
        } else {
          // Android 12 and below
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting storage permissions: $e');
      return false;
    }
  }

  /// Check camera permission
  Future<bool> hasCameraPermission() async {
    if (kIsWeb) {
      return true; // Web handles camera permissions through browser
    }

    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      if (kIsWeb) {
        return true; // Web handles camera permissions through browser
      }

      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Check if permission is permanently denied
  Future<bool> isStoragePermissionPermanentlyDenied() async {
    if (kIsWeb || Platform.isIOS) {
      return false; // iOS doesn't have permanently denied concept like Android
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final photos = await Permission.photos.status;
        final videos = await Permission.videos.status;
        return photos.isPermanentlyDenied || videos.isPermanentlyDenied;
      } else {
        final storage = await Permission.storage.status;
        return storage.isPermanentlyDenied;
      }
    }

    return false;
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await Permission.photos.request().then((status) async {
        if (status.isPermanentlyDenied) {
          return await Permission.photos.request() == PermissionStatus.granted;
        }
        return status.isGranted;
      });
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Get storage permission status description
  Future<String> getStoragePermissionStatusDescription() async {
    if (kIsWeb) {
      return 'Web platform - no explicit permissions needed';
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      switch (status) {
        case PermissionStatus.granted:
          return 'Photo library access granted';
        case PermissionStatus.denied:
          return 'Photo library access denied';
        case PermissionStatus.restricted:
          return 'Photo library access restricted';
        case PermissionStatus.limited:
          return 'Limited photo library access';
        case PermissionStatus.permanentlyDenied:
          return 'Photo library access permanently denied';
        default:
          return 'Photo library permission status unknown';
      }
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final photos = await Permission.photos.status;
        final videos = await Permission.videos.status;
        return 'Photos: ${photos.name}, Videos: ${videos.name}';
      } else {
        final storage = await Permission.storage.status;
        return 'Storage: ${storage.name}';
      }
    }

    return 'Unknown platform';
  }

  /// Request all media permissions (photos, videos, camera)
  Future<Map<String, bool>> requestAllMediaPermissions() async {
    final results = <String, bool>{};

    try {
      // Request storage/photos permissions
      results['storage'] = await requestStoragePermissions();
      
      // Request camera permission
      results['camera'] = await requestCameraPermission();

      debugPrint('Media permissions results: $results');
      return results;
    } catch (e) {
      debugPrint('Error requesting all media permissions: $e');
      return {
        'storage': false,
        'camera': false,
      };
    }
  }

  /// Check if all required media permissions are granted
  Future<bool> hasAllMediaPermissions() async {
    try {
      final storage = await hasStoragePermissions();
      final camera = await hasCameraPermission();
      
      return storage && camera;
    } catch (e) {
      debugPrint('Error checking all media permissions: $e');
      return false;
    }
  }
}
