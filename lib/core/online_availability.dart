import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart" show TargetPlatform, defaultTargetPlatform;
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Used only by `main.dart` to decide whether to attempt Firebase init at
/// all (see `firebase_options.dart` — Android only until an iOS app is
/// registered). Not used for UI gating — see `onlineAvailableProvider`.
bool isOnlinePlatformSupported({TargetPlatform? platform}) =>
    (platform ?? defaultTargetPlatform) == TargetPlatform.android;

/// True iff a Firebase app actually initialized successfully. Deliberately
/// keyed off `Firebase.apps`, not `defaultTargetPlatform` — the latter is
/// always `TargetPlatform.android` inside `flutter test` regardless of
/// host OS, which would make a platform-based check always true there.
final onlineAvailableProvider =
    Provider<bool>((ref) => Firebase.apps.isNotEmpty);
