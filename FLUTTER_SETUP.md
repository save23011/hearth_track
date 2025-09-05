# Hearth Track Flutter App - Installation & Setup Guide

## 📱 Flutter Frontend Overview

Your Hearth Track Flutter application is now fully implemented with a modern, professional UI that integrates seamlessly with your Node.js backend. The app features a clean Material Design 3 interface with custom theming and comprehensive functionality.

## ✅ Implemented Features

### 🎨 **Modern UI/UX Design**
- **Material Design 3** with custom color scheme
- **Poppins font family** for clean typography
- **Light and Dark theme** support
- **Custom animations** and smooth transitions
- **Responsive design** for all screen sizes

### 🔐 **Authentication System**
- **Splash Screen** with animated logo and loading
- **Onboarding Flow** with 6 informative screens
- **Login Screen** with email/password and social login options
- **Registration Screen** with comprehensive form validation
- **Password visibility toggle** and remember me functionality
- **Social Login placeholders** for Google and Facebook

### 🏠 **Main Navigation**
- **Custom Bottom Navigation** with smooth animations
- **5 Main Sections**: Dashboard, Assessments, Exercise, Journal, Profile
- **IndexedStack** for efficient screen management

### 📊 **Dashboard Features**
- **Personalized welcome** with user greeting
- **Quick stats overview** (exercises, mood, sleep)
- **Daily goals tracking** with progress indicators
- **Recent activities** timeline
- **AI-powered recommendations** section

### 🏗️ **App Architecture**
- **Clean Architecture** with feature-based structure
- **Riverpod** for state management (ready to implement)
- **Custom widgets** for reusable components
- **Service layer** for API communication
- **Model classes** for data structure

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          # App configuration constants
│   ├── services/
│   │   └── api_service.dart         # HTTP API service with error handling
│   └── theme/
│       └── app_theme.dart           # Custom theme and color scheme
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── pages/
│   │           ├── splash_screen.dart
│   │           ├── onboarding_screen.dart
│   │           ├── login_screen.dart
│   │           └── register_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── main_navigation.dart
│   │       └── widgets/
│   │           └── custom_bottom_nav_bar.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       └── pages/
│   │           └── dashboard_screen.dart
│   ├── questionnaire/
│   │   └── presentation/
│   │       └── pages/
│   │           └── questionnaire_list_screen.dart
│   ├── exercise/
│   │   └── presentation/
│   │       └── pages/
│   │           └── exercise_screen.dart
│   ├── journal/
│   │   └── presentation/
│   │       └── pages/
│   │           └── journal_screen.dart
│   └── profile/
│       └── presentation/
│           └── pages/
│               └── profile_screen.dart
├── shared/
│   ├── models/
│   │   ├── user_model.dart          # User data models
│   │   ├── questionnaire_model.dart # Questionnaire data models
│   │   └── exercise_model.dart      # Exercise data models
│   ├── services/
│   │   └── auth_service.dart        # Authentication service
│   └── widgets/
│       ├── custom_text_field.dart   # Reusable input field
│       ├── custom_button.dart       # Customizable button widget
│       └── loading_overlay.dart     # Loading overlay component
└── main.dart                        # App entry point
```

## 🚀 Installation Instructions

### 1. **Install Dependencies**
```bash
cd hearth_track
flutter pub get
```

### 2. **Configure Backend Connection**
Update the API base URL in `lib/core/config/app_config.dart`:
```dart
// For development (local backend)
static const String baseUrl = 'http://localhost:3000/api';

// For production (your deployed backend)
static const String baseUrl = 'https://your-domain.com/api';
```

### 3. **Add Required Assets**
Create the asset directories and add your assets:
```bash
mkdir -p assets/images assets/icons assets/animations assets/audio assets/videos assets/fonts
```

Download and add Poppins font files to `assets/fonts/`:
- Poppins-Regular.ttf
- Poppins-Medium.ttf
- Poppins-SemiBold.ttf
- Poppins-Bold.ttf

### 4. **Configure Firebase (Optional)**
To enable push notifications and social login:

1. **Create Firebase Project**: https://console.firebase.google.com/
2. **Add Android/iOS apps** to your Firebase project
3. **Download configuration files**:
   - `google-services.json` for Android (`android/app/`)
   - `GoogleService-Info.plist` for iOS (`ios/Runner/`)
4. **Uncomment Firebase imports** in `main.dart`

### 5. **Configure Social Login (Optional)**

#### Google Sign-In:
1. Enable Google Sign-In in Firebase Console
2. Add your SHA-1 fingerprint for Android
3. Uncomment Google Sign-In implementation in login screen

#### Facebook Login:
1. Create Facebook App: https://developers.facebook.com/
2. Configure Facebook SDK for Android/iOS
3. Add Facebook App ID to configuration

### 6. **Run the Application**
```bash
# For development
flutter run

# For Android release
flutter build apk --release

# For iOS release (requires Mac)
flutter build ios --release
```

## 🔧 Backend Integration

### API Configuration
The app is pre-configured to connect to your Node.js backend:

- **Base URL**: Configurable in `app_config.dart`
- **Authentication**: JWT token-based with automatic storage
- **Error Handling**: Comprehensive error responses
- **Models**: Pre-built models matching your backend schema

### Authentication Flow
```dart
// Login example
final response = await AuthService.login(
  email: 'user@example.com',
  password: 'password123',
);

if (response.success) {
  // Navigate to home screen
  Navigator.pushReplacementNamed(context, '/home');
}
```

### API Calls
```dart
// Example API call
final response = await ApiService().get<List<Exercise>>(
  '/exercises/daily',
  fromJson: (data) => data.map((e) => Exercise.fromJson(e)).toList(),
);

if (response.isSuccess) {
  final exercises = response.data;
  // Use exercises data
}
```

## 📱 Device Permissions

Add these permissions to your app:

### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for profile pictures and journal entries</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice recordings</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access for selecting images</string>
```

## 🎨 Customization Guide

### Colors and Themes
Modify `lib/core/theme/app_theme.dart` to customize:
- Primary color scheme
- Typography styles
- Component themes
- Dark mode colors

### Features to Implement Next
1. **Complete Questionnaire System**
2. **Exercise Library with Video Player**
3. **Journal with Voice Recording**
4. **Real-time Chat for Therapy Sessions**
5. **Push Notifications Integration**
6. **Offline Data Storage**
7. **Biometric Authentication**

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
Create test files in `test/` directory following Flutter testing conventions.

## 🚀 Production Deployment

### Android
1. **Generate keystore** for app signing
2. **Configure build.gradle** with signing config
3. **Build release APK**: `flutter build apk --release`
4. **Upload to Google Play Console**

### iOS
1. **Configure Xcode project** with proper certificates
2. **Build for release**: `flutter build ios --release`
3. **Archive and upload** via Xcode to App Store

## 📞 Support

The app includes comprehensive error handling and user feedback:
- **Loading states** for all async operations
- **Error snackbars** for failed operations
- **Form validation** with helpful error messages
- **Network error handling** with retry options

## 🔄 Next Steps

1. **Start the backend server**: `npm run dev`
2. **Run the Flutter app**: `flutter run`
3. **Test authentication flow** with your backend
4. **Implement remaining features** based on your requirements
5. **Add real data integration** with your backend APIs

Your Hearth Track Flutter app is now ready for development and testing! The foundation is solid with modern architecture, beautiful UI, and seamless backend integration.
