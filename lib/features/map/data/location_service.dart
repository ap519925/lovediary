import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationInfo {
  final String city;
  final String country;
  final String fullAddress;
  
  LocationInfo({
    required this.city,
    required this.country,
    required this.fullAddress,
  });
  
  @override
  String toString() => '$city, $country';
}

class LocationService {
  // Using free reverse geocoding API
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/reverse';
  
  /// Get location information from coordinates
  static Future<LocationInfo?> getLocationInfo(LatLng position) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?format=json&lat=${position.latitude}&lon=${position.longitude}'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'LoveDiary/1.0', // Required by Nominatim API
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract address components
        final address = data['address'];
        final city = address['city'] ?? 
                    address['town'] ?? 
                    address['village'] ?? 
                    address['hamlet'] ?? 
                    address['suburb'] ?? 
                    'Unknown';
                    
        final country = address['country'] ?? 'Unknown';
        final fullAddress = data['display_name'] ?? '$city, $country';
        
        return LocationInfo(
          city: city,
          country: country,
          fullAddress: fullAddress,
        );
      }
      return null;
    } catch (e) {
      print('Error getting location info: $e');
      return null;
    }
  }
  
  /// Calculate distance between two points in kilometers
  static double calculateDistance(LatLng point1, LatLng point2) {
    // Using the Haversine formula
    const double earthRadius = 6371; // in kilometers
    
    double toRadians(double degree) {
      return degree * (3.141592653589793 / 180);
    }
    
    final double lat1 = toRadians(point1.latitude);
    final double lon1 = toRadians(point1.longitude);
    final double lat2 = toRadians(point2.latitude);
    final double lon2 = toRadians(point2.longitude);
    
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    
    final double a = 
        (1 - math.cos(dLat)) / 2 +
        math.cos(lat1) * math.cos(lat2) * (1 - math.cos(dLon)) / 2;
    
    final double distance = 2 * earthRadius * math.asin(math.sqrt(a));
    return distance;
  }
}
