# Love Diary

<p align="center">
  <img src="assets/logo.png" alt="Love Diary Logo" width="200"/>
</p>

<p align="center">
  <b>A modern relationship app for couples to stay connected, share moments, and track their journey together.</b>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#technologies">Technologies</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#internationalization">Internationalization</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

## Features

Love Diary is a feature-rich relationship app designed to help couples stay connected and document their journey together:

- **User Authentication**: Secure sign-up and login with email/password or social media accounts
- **Profile Management**: Personalized profiles with customizable avatars and relationship status
- **Partner Connection**: Connect with your partner using unique user codes
- **Distance Tracker**: Real-time location sharing with custom markers showing both partners' locations
- **Relationship Timeline**: Document and share special moments with your partner
- **Multilingual Support**: Available in English and Chinese, with easy language switching
- **Theme Customization**: Light and dark mode support
- **AI Insights**: Get relationship insights based on your interactions and posts
- **Gamification**: Earn points and achievements for relationship milestones
- **Cross-Platform**: Available on iOS, Android, and Web

## Screenshots

<p align="center">
  <img src="https://via.placeholder.com/200x400" alt="Login Screen" width="200"/>
</p>

## Architecture

Love Diary follows a clean architecture approach with BLoC pattern for state management:

```
lib/
├── app.dart                  # App entry point
├── main.dart                 # Main configuration
├── core/                     # Core utilities and shared components
├── features/                 # Feature modules
│   ├── auth/                 # Authentication feature
│   ├── profile/              # Profile management
│   ├── map/                  # Location tracking
│   ├── relationship/         # Relationship management
│   ├── ai_insights/          # AI-powered relationship insights
│   ├── gamification/         # Gamification elements
│   ├── language/             # Language switching
│   ├── theme/                # Theme management
│   └── ...
├── l10n/                     # Localization resources
└── gen/                      # Generated code
```

Each feature follows a layered architecture:

- **Presentation**: UI components, screens, and BLoC classes
- **Domain**: Business logic and use cases
- **Data**: Repositories, data sources, and models

## Technologies

- **Flutter**: Cross-platform UI framework
- **Firebase**: Backend services
  - Authentication
  - Firestore (database)
  - Storage (media storage)
  - Cloud Functions
- **BLoC Pattern**: State management
- **Google Maps**: Location services
- **Internationalization**: Multi-language support
- **Responsive Design**: Adapts to different screen sizes

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode
- Firebase account

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/lovediary.git
   cd lovediary
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Create a new Firebase project
   - Add Android, iOS, and Web apps to your Firebase project
   - Download and add the configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS
     - Update web/index.html with Firebase config for Web

4. Run the app:
   ```bash
   flutter run
   ```

### Firebase Configuration

For proper functionality, ensure these Firebase services are enabled:
- Authentication (Email/Password and Google Sign-In)
- Cloud Firestore
- Storage
- Cloud Functions (optional for advanced features)

## Internationalization

Love Diary supports multiple languages through Flutter's internationalization system:

- English (default)
- Chinese

To add a new language:
1. Create a new ARB file in the `lib/l10n` directory
2. Run the app to generate the localization files
3. Update the language selector to include the new language

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<p align="center">
  Made with ❤️ for couples everywhere
</p>
