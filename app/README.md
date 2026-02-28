# Ticket Management System - Flutter App

Production-ready Flutter application with role-based routing, Firebase authentication, and clean architecture.

## Architecture

### Tech Stack
- **Flutter**: Cross-platform mobile framework
- **Provider**: State management
- **Firebase Auth**: Google Sign-In authentication
- **Dio**: HTTP client with interceptors
- **Clean Architecture**: Separation of concerns

### Folder Structure
```
lib/
├── core/
│   ├── auth/
│   │   ├── auth_provider.dart       # Authentication state management
│   │   └── token_manager.dart       # Firebase token storage
│   ├── guards/
│   │   └── role_guard.dart          # Role validation widget
│   ├── models/
│   │   ├── request_model.dart
│   │   ├── comment_model.dart
│   │   ├── assignment_model.dart
│   │   └── store_request_model.dart
│   └── network/
│       ├── dio_client.dart          # Dio configuration with interceptors
│       └── api_service.dart         # Centralized API calls
├── features/
│   ├── auth/
│   │   └── screens/
│   │       └── login_screen.dart
│   ├── user/
│   │   └── screens/
│   │       └── user_home_screen.dart
│   ├── admin/
│   │   └── screens/
│   │       └── admin_home_screen.dart
│   ├── staff/
│   │   └── screens/
│   │       └── staff_home_screen.dart
│   └── store/
│       └── screens/
│           └── store_home_screen.dart
└── main.dart                        # App entry point with routing
```

## Setup

### 1. Install Flutter
```bash
# Follow official Flutter installation guide
# https://docs.flutter.dev/get-started/install
```

### 2. Install Dependencies
```bash
cd flutter_app
flutter pub get
```

### 3. Configure Firebase

#### Android
1. Create Firebase project at https://console.firebase.google.com
2. Add Android app to Firebase project
3. Download `google-services.json`
4. Place in `android/app/`
5. Enable Google Sign-In in Firebase Console

#### iOS
1. Add iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/`
4. Enable Google Sign-In in Firebase Console

### 4. Update API Base URL
Edit `lib/core/network/dio_client.dart`:
```dart
baseUrl: 'https://your-api-domain.com/api/v1',
```

### 5. Run Application
```bash
# Development
flutter run

# Release build
flutter build apk  # Android
flutter build ios  # iOS
```

## Authentication Flow

1. **User clicks "Sign in with Google"**
2. **Firebase handles Google OAuth**
3. **App retrieves Firebase ID token**
4. **Token stored in SharedPreferences**
5. **Token sent to backend in Authorization header**
6. **Backend verifies token and returns user with role**
7. **App routes to appropriate home screen based on role**

## Role-Based Routing

The app automatically routes users to the correct screen based on their role:

- **USER** → `UserHomeScreen`
- **ADMIN** → `AdminHomeScreen`
- **STAFF** → `StaffHomeScreen`
- **STORE** → `StoreHomeScreen`

Routing logic in `main.dart`:
```dart
Widget _getHomeScreen(String role) {
  switch (role) {
    case 'USER': return const UserHomeScreen();
    case 'ADMIN': return const AdminHomeScreen();
    case 'STAFF': return const StaffHomeScreen();
    case 'STORE': return const StoreHomeScreen();
    default: return const Scaffold(body: Center(child: Text('Invalid role')));
  }
}
```

## API Service

Centralized API calls in `api_service.dart`:

### USER Endpoints
```dart
await apiService.createRequest(mainTypeId: 1, subTypeId: 2, description: 'Issue');
await apiService.getMyRequests(page: 1);
await apiService.replyToRequest(requestId, message);
await apiService.getRequestComments(requestId);
```

### ADMIN Endpoints
```dart
await apiService.getAllRequests(statusFilter: 'RAISED');
await apiService.rejectRequest(requestId, reason);
await apiService.assignStaff(requestId, [staffId1, staffId2]);
await apiService.reassignStaff(requestId: id, newStaffIds: [...], reason: '...');
await apiService.uploadRolesCsv(filePath);
```

### STAFF Endpoints
```dart
await apiService.getAssignedRequests();
await apiService.startRequest(requestId);
await apiService.completeRequest(requestId);
await apiService.forwardRequest(requestId, reason);
await apiService.createEquipmentRequest(parentRequestId: id, description: '...');
```

### STORE Endpoints
```dart
await apiService.getAllStoreRequests(statusFilter: 'PENDING');
await apiService.approveEquipmentRequest(requestId, comment);
await apiService.rejectEquipmentRequest(requestId, comment);
await apiService.fulfillEquipmentRequest(requestId);
```

## Dio Interceptor

Automatic token attachment to all requests:

```dart
_dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await TokenManager.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        TokenManager.clearToken();
        // Navigate to login
      }
      return handler.next(error);
    },
  ),
);
```

## State Management

Using Provider for authentication state:

```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ],
  child: const MyApp(),
)

// In widgets
final authProvider = Provider.of<AuthProvider>(context);
await authProvider.signInWithGoogle();
await authProvider.signOut();
```

## Security Best Practices

1. **No business logic in UI** - All logic in backend
2. **Token auto-refresh** - Firebase handles token refresh
3. **Secure storage** - Tokens stored in SharedPreferences
4. **Role validation** - RoleGuard widget validates roles
5. **Error handling** - Global error interceptor
6. **HTTPS only** - Production API must use HTTPS

## Features by Role

### USER (Lab Technician)
- View own requests
- Create new requests
- Reply to admin comments
- View request timeline

### ADMIN
- View all requests
- Reject/Reply to requests
- Assign/Reassign staff
- Manage request types
- Upload role CSV

### STAFF (Service Staff)
- View assigned requests
- Start/Complete requests
- Forward requests to admin
- Create equipment requests

### STORE
- View equipment requests
- Approve/Reject requests
- Mark as fulfilled

## Building for Production

### Android
```bash
# Generate release APK
flutter build apk --release

# Generate App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Generate release IPA
flutter build ios --release

# Archive in Xcode for App Store
open ios/Runner.xcworkspace
```

## Environment Configuration

Create different environments:

```dart
// lib/core/config/environment.dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}

// Run with environment variable
flutter run --dart-define=API_BASE_URL=https://api.production.com/api/v1
```

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## Common Issues

### Firebase Configuration
- Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in correct locations
- Enable Google Sign-In in Firebase Console
- Add SHA-1 fingerprint for Android

### API Connection
- Update base URL in `dio_client.dart`
- Ensure backend is running and accessible
- Check CORS configuration on backend

### Token Issues
- Token automatically refreshed by Firebase
- Clear app data if persistent issues
- Check token expiration in backend logs

## Performance Optimization

1. **Lazy loading** - Load data on demand
2. **Pagination** - Implemented in list views
3. **Caching** - Use SharedPreferences for offline data
4. **Image optimization** - Compress images before upload
5. **Code splitting** - Separate features into modules

## Deployment Checklist

- [ ] Update API base URL to production
- [ ] Configure Firebase for production
- [ ] Enable ProGuard/R8 (Android)
- [ ] Configure app signing
- [ ] Test on physical devices
- [ ] Enable crash reporting (Firebase Crashlytics)
- [ ] Set up analytics (Firebase Analytics)
- [ ] Configure push notifications (optional)
- [ ] Test all role-based flows
- [ ] Verify token refresh mechanism
