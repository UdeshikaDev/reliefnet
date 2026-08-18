// lib/firebase_options.dart
//
// ⚠️ REPLACE THIS ENTIRE FILE — do not edit these placeholder values by
// hand. The correct way to generate this file is:
//
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure
//
// That command logs into your actual Firebase project and writes the real
// API keys, app IDs, and project IDs here for whichever platforms you
// select (Android/iOS/web). I cannot run that command from this
// environment — it requires your Firebase CLI login — so what's below is a
// non-functional placeholder purely so the rest of the app compiles before
// you've generated the real file. Firebase.initializeApp() will fail at
// runtime until you replace this.
//
// [Unverified] This file's *shape* matches what `flutterfire configure`
// generates (confirmed via FlutterFire's own documentation), but every
// value in it is a placeholder, not a real credential.

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform. '
          'Run `flutterfire configure` to generate real values.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    authDomain: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAoRbKFt8TDOWH5AY3SudUto--f19Gi0rY',
    appId: '1:165720386337:android:31fa6ae227f16b2ce92c60',
    messagingSenderId: '165720386337',
    projectId: 'reliefnet-app-c42ee',
    storageBucket: 'reliefnet-app-c42ee.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCbaWbx1vOtkJtdBtrtYIiBHjFCdC8QSO8',
    appId: '1:165720386337:ios:1b8fde85b2c33c2ce92c60',
    messagingSenderId: '165720386337',
    projectId: 'reliefnet-app-c42ee',
    storageBucket: 'reliefnet-app-c42ee.firebasestorage.app',
    iosBundleId: 'com.reliefnet.reliefnet',
  );
}
