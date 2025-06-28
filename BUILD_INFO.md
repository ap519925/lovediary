# Love Diary APK Build Information

## Build Details
- **Build Date**: June 27, 2025
- **Build Type**: Release APK
- **File Size**: 299.9 MB (314,458,653 bytes)
- **Location**: `build/app/outputs/flutter-apk/app-release.apk`
- **SHA1 Hash**: Available in `app-release.apk.sha1`

## Build Configuration
- **Flutter Version**: Latest stable
- **Target Platform**: Android
- **Build Mode**: Release (optimized for production)
- **Minimum SDK**: As configured in `android/app/build.gradle.kts`

## Features Included
- ✅ Firebase Authentication
- ✅ Firebase Firestore Database
- ✅ Firebase Storage
- ✅ Firebase Crashlytics (Error Reporting)
- ✅ Google Maps Integration
- ✅ Location Services
- ✅ Image Picker & Camera
- ✅ Video/Voice Calling (Agora)
- ✅ Real-time Chat
- ✅ AI Insights
- ✅ Multi-language Support (English/Chinese)
- ✅ Theme Management (Light/Dark/System)
- ✅ Gamification Features
- ✅ Calendar Integration

## Installation Instructions
1. Enable "Install from Unknown Sources" in Android settings
2. Transfer the APK file to your Android device
3. Tap the APK file to install
4. Grant necessary permissions when prompted

## Required Permissions
- Camera (for profile pictures and posts)
- Storage (for saving images)
- Location (for map features)
- Microphone (for voice calls)
- Internet (for Firebase services)

## Notes
- This is a release build optimized for performance
- Debug information has been stripped for smaller size
- All dependencies are bundled within the APK
- The app requires an active internet connection for most features

## Troubleshooting
If you encounter issues:
1. Ensure your device runs Android 5.0 (API 21) or higher
2. Check that you have sufficient storage space (at least 500MB free)
3. Verify internet connectivity for Firebase services
4. Refer to `FIRESTORE_SETUP.md` for database configuration

## Security
- The APK is signed with a release key
- All Firebase API keys are properly configured
- Error reporting is enabled for crash monitoring
