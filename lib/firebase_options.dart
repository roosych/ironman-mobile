// Generated from firebase-configs/dev/ plist and google-services.json
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDD1RKUyKes9o7Pw3Yucv3CKRFiXFrnIRY',
    appId: '1:46649103584:ios:f10b9d4fe0f9fd0417ec85',
    messagingSenderId: '46649103584',
    projectId: 'ironmanapp-dev',
    storageBucket: 'ironmanapp-dev.firebasestorage.app',
    iosBundleId: 'ironstatsmobiledev',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRjjx6R0VFPQen_W9F2EK_EONRo-jP_1A',
    appId: '1:46649103584:android:15b7c900a2ebc8ad17ec85',
    messagingSenderId: '46649103584',
    projectId: 'ironmanapp-dev',
    storageBucket: 'ironmanapp-dev.firebasestorage.app',
  );
}
