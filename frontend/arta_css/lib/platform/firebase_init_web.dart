// Firebase initialization for web platform
// Currently disabled - using HTTP API for all platforms

// To enable Firebase on web-only builds:
// 1. Uncomment firebase_core and cloud_firestore in pubspec.yaml
// 2. Uncomment the imports and code below
// 3. Update service_factory_web.dart to use Firebase services

// import 'package:firebase_core/firebase_core.dart';
// import '../firebase_options.dart';

Future<void> initializeFirebase() async {
  // Firebase disabled - using HTTP API instead
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
}
