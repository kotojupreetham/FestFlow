# Local Setup and Configuration Guide

This guide explains how to set up FestFlow locally on your machine for development or testing.

## Prerequisites

Ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.6.2 or higher)
- [Dart SDK](https://dart.dev/get-started) (v3.6.x)
- Android Studio / VS Code with Flutter extensions
- Git

---

## 1. Setup Firebase Configuration

FestFlow is built on top of Firebase services. Because the production credentials are kept private for security, you need to create your own Firebase project to run the application:

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project (e.g. `festflow-dev`).
2. Enable the following services in your Firebase project:
   - **Firebase Authentication**: Enable Google Sign-In and Email/Password providers.
   - **Cloud Firestore NoSQL Database**: Start in test mode or define security rules.
   - **Firebase Storage**: For event banners and profile photos.
3. Install the Firebase CLI: `npm install -g firebase-tools`.
4. Log in and configure your Flutter apps with FlutterFire:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. This command will automatically generate `lib/firebase_options.dart` and download `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS). These files are blocked by `.gitignore` to prevent secret leaks.

*Note: You can check [lib/firebase_options.dart.example](../lib/firebase_options.dart.example) for the expected structure.*

---

## 2. Environment Variables

FestFlow uses the Google Gemini API to generate AI event reports.

1. Obtain a Gemini API key from the [Google AI Studio](https://aistudio.google.com/).
2. Copy `.env.example` to `.env` in the root folder:
   ```bash
   cp .env.example .env
   ```
3. Set your Gemini API key in the `.env` file:
   ```env
   GEMINI_API_KEY=your_actual_api_key_here
   ```
4. During compile-time, compile with the key via `--dart-define`:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_actual_api_key_here
   ```

---

## 3. Running the App

After configuring your Firebase settings, navigate to the root directory and run:

```bash
# Fetch dependencies
flutter pub get

# Run the app
flutter run
```

---

## 4. Admin Web Dashboard Setup

The `admin_dashboard/` contains a web-based management portal. To run it:

1. Open `admin_dashboard/script.js`.
2. Locate the `firebaseConfig` object and populate it with your Firebase project credentials (from the Firebase Console settings -> Web App).
3. Open `admin_dashboard/index.html` in your browser, or host it locally:
   ```bash
   cd admin_dashboard
   npx serve .
   ```
