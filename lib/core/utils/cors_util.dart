import 'dart:convert';
import 'dart:io';
import 'package:lovediary/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Utility class for handling CORS configuration
class CorsUtil {
  static const String _tag = 'CorsUtil';
  
  /// Private constructor to prevent instantiation
  CorsUtil._();
  
  /// Default CORS configuration
  static const Map<String, dynamic> defaultCorsConfig = {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"],
    "maxAgeSeconds": 3600,
    "responseHeader": [
      "Content-Type", 
      "Authorization", 
      "Range", 
      "X-Goog-Upload-Command", 
      "X-Goog-Upload-Content-Length", 
      "X-Goog-Upload-Offset", 
      "X-Goog-Upload-Protocol",
      "X-Goog-Upload-Status", 
      "X-Goog-Upload-Size-Received"
    ]
  };
  
  /// Check if CORS is properly configured for Firebase Storage
  static Future<bool> checkCorsConfiguration(String bucketUrl) async {
    try {
      Logger.d(_tag, 'Checking CORS configuration for: $bucketUrl');
      
      // Make a HEAD request to check CORS headers (since OPTIONS might not be available)
      final response = await http.head(
        Uri.parse('$bucketUrl/o'),
        headers: {
          'Origin': 'http://localhost',
        },
      );
      
      // Check if CORS headers are present
      final corsHeadersPresent = response.headers.containsKey('access-control-allow-origin');
      
      Logger.i(_tag, 'CORS headers present: $corsHeadersPresent');
      Logger.d(_tag, 'Response headers: ${response.headers}');
      
      return corsHeadersPresent;
    } catch (e) {
      Logger.e(_tag, 'Error checking CORS configuration', e);
      return false;
    }
  }
  
  /// Generate a CORS configuration file
  static Future<File> generateCorsConfigFile(List<Map<String, dynamic>> corsConfig) async {
    try {
      Logger.d(_tag, 'Generating CORS configuration file');
      
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/cors.json';
      
      // Create the file
      final file = File(filePath);
      await file.writeAsString(jsonEncode(corsConfig));
      
      Logger.i(_tag, 'CORS configuration file generated at: $filePath');
      return file;
    } catch (e) {
      Logger.e(_tag, 'Error generating CORS configuration file', e);
      rethrow;
    }
  }
  
  /// Get instructions for applying CORS configuration
  static String getCorsInstructions(String bucketName) {
    return '''
# Firebase Storage CORS Configuration Instructions

To fix CORS issues with Firebase Storage, follow these steps:

## Option 1: Using Google Cloud Console (Recommended)
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to Cloud Storage > Browser
4. Find your bucket: $bucketName
5. Click on the bucket name
6. Go to the "Permissions" tab
7. Click "Add Principal"
8. Add `allUsers` with role `Storage Object Viewer`
9. Click "Save"

## Option 2: Using Google Cloud SDK
1. Install Google Cloud SDK from: https://cloud.google.com/sdk/docs/install
2. Open command prompt and run:
   ```bash
   gcloud auth login
   gcloud config set project ${bucketName.split('.')[0]}
   gsutil cors set cors.json gs://$bucketName
   ```

## Option 3: Using Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Storage
4. Click on "Rules" tab
5. Update your rules to allow read/write:
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

After applying any of the above solutions:
1. Clear your browser cache
2. Restart your Flutter web development server
3. Try uploading an image again
''';
  }
}
