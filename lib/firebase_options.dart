// Firebase configuration for all platforms
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError('Windows not supported');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not supported');
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  // Web uses erp-f4ef1 project
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCQ4rjb7yvj7a9BTnx3AHjoqu2XHUF_Y60",
    authDomain: "erp-f4ef1.firebaseapp.com",
    projectId: "erp-f4ef1",
    storageBucket: "erp-f4ef1.firebasestorage.app",
    messagingSenderId: "698979802420",
    appId: "1:698979802420:web:492a492b16ed51a7151961",
  );

  // Android uses erp-f4ef1 project
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyB8uAL9Kbd72B1e1bbqKW__EMHCRb-KdWM",
    authDomain: "erp-f4ef1.firebaseapp.com",
    projectId: "erp-f4ef1",
    storageBucket: "erp-f4ef1.firebasestorage.app",
    messagingSenderId: "698979802420",
    appId: "1:698979802420:android:68479bd2632a9903151961",
  );

  // iOS - using erp-f4ef1 project (same as Android)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyB8uAL9Kbd72B1e1bbqKW__EMHCRb-KdWM",
    authDomain: "erp-f4ef1.firebaseapp.com",
    projectId: "erp-f4ef1",
    storageBucket: "erp-f4ef1.firebasestorage.app",
    messagingSenderId: "698979802420",
    appId: "1:698979802420:ios:placeholder",
  );

  // macOS - using erp-f4ef1 project (same as Android)
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyB8uAL9Kbd72B1e1bbqKW__EMHCRb-KdWM",
    authDomain: "erp-f4ef1.firebaseapp.com",
    projectId: "erp-f4ef1",
    storageBucket: "erp-f4ef1.firebasestorage.app",
    messagingSenderId: "698979802420",
    appId: "1:698979802420:macos:placeholder",
  );
}

