// File generated for daily-wordnote Firebase project
// DO NOT commit this file to public repositories (contains API keys)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not supported.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCa_SLEnXO-Thv50K0wEGK0s-X4dn3P-A',
    appId: '1:169245869660:android:570740e2ad8360f7070899',
    messagingSenderId: '169245869660',
    projectId: 'daily-wordnote',
    storageBucket: 'daily-wordnote.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBpf41W25ErMGXXo6XJpXao84pH6-N4rWM',
    appId: '1:169245869660:ios:2ceed96396785cfc070899',
    messagingSenderId: '169245869660',
    projectId: 'daily-wordnote',
    storageBucket: 'daily-wordnote.firebasestorage.app',
    iosClientId: 'com.logosflow.dailyWordnote',
    iosBundleId: 'com.logosflow.dailyWordnote',
  );
}
