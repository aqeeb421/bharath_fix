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
    apiKey: 'AIzaSyCxTasfW4mGS6zWGDRZDL-5WI3icEwglbA',
    appId: '1:233649114123:web:9d801fb604364dbee74b0e',
    messagingSenderId: '233649114123',
    projectId: 'my-work-c68d9',
    authDomain: 'my-work-c68d9.firebaseapp.com',
    storageBucket: 'my-work-c68d9.firebasestorage.app',
  );
}
