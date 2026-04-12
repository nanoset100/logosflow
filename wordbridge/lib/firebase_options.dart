// File generated based on GoogleService-Info.plist
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android.',
        );
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // GoogleService-Info.plist 기반 (com.logosflow.wordbridge)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDbJrJ7e2RPkydQD5O8N2MOpG9ei0QnU_s',
    appId: '1:69323558263:ios:61ea40ec9e72e6e8d9e572',
    messagingSenderId: '69323558263',
    projectId: 'chimshin-bible-note',
    storageBucket: 'chimshin-bible-note.firebasestorage.app',
    iosBundleId: 'com.logosflow.wordbridge',
    iosClientId: '69323558263-qhbniipp490k3ge7rcqaft8m7imvmc6s.apps.googleusercontent.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDbJrJ7e2RPkydQD5O8N2MOpG9ei0QnU_s',
    appId: '1:69323558263:ios:61ea40ec9e72e6e8d9e572',
    messagingSenderId: '69323558263',
    projectId: 'chimshin-bible-note',
    storageBucket: 'chimshin-bible-note.firebasestorage.app',
    iosBundleId: 'com.logosflow.wordbridge',
    iosClientId: '69323558263-qhbniipp490k3ge7rcqaft8m7imvmc6s.apps.googleusercontent.com',
  );
}
