// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Default [FirebaseOptions] for use in initializing Firebase.
/// Fill in your web configuration keys below.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAAQtuV24LYxgFxyh7TcvJjDHKIhLQJuMo",
    authDomain: "bharathfix-735c5.firebaseapp.com",
    projectId: "bharathfix-735c5",
    storageBucket: "bharathfix-735c5.firebasestorage.app",
    messagingSenderId: "364440228818",
    appId: "1:364440228818:web:97ed09ca1f57cb2a74ee0b",
    measurementId: "G-EWV4LDMG0R",
  );
}
