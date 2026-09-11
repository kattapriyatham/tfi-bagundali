import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "app.dart";
import "core/firebase_options.dart";
import "core/online_availability.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isOnlinePlatformSupported()) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (const bool.fromEnvironment("USE_FIREBASE_EMULATOR")) {
        await FirebaseAuth.instance.useAuthEmulator("localhost", 9099);
        FirebaseDatabase.instance.useDatabaseEmulator("localhost", 9000);
        FirebaseFirestore.instance.useFirestoreEmulator("localhost", 8080);
      }
    } catch (_) {
      // Online mode degrades to unavailable; the rest of the app (solo,
      // 2-player, ads) must never be blocked by a Firebase init failure.
    }
  }
  runApp(const ProviderScope(child: MyApp()));
}
