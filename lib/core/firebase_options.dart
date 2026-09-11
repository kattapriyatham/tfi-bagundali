import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart" show TargetPlatform, defaultTargetPlatform;

/// Firebase project config for `spndex-37b0d`. Android only for now — no
/// iOS Firebase app is registered yet.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      "DefaultFirebaseOptions is only configured for Android in this build",
    );
  }

  static const android = FirebaseOptions(
    apiKey: "AIzaSyBc6xbRstTU9XM4koJ2QUUyKHJ2BQQ9fqY",
    appId: "1:107625876912:android:1bd1e1d4094198db601a75",
    messagingSenderId: "107625876912",
    projectId: "spndex-37b0d",
    storageBucket: "spndex-37b0d.firebasestorage.app",
    databaseURL: "https://spndex-37b0d-default-rtdb.firebaseio.com",
  );
}
