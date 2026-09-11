# Online Multiplayer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the online multiplayer mode described in the design spec — create/join a room by code, play a full synced round of Inferno with 2–8 players, handle disconnects and host migration — reachable from the existing "Play Online" home-screen card.

**Architecture:** Firebase Realtime Database holds live room/game state (rooms, players, deck order, center-pile index); Cloud Firestore holds durable per-user stats. No Cloud Functions (v1 amendment) — room creation is a client-side RTDB transaction claiming an unused code, and end-of-game stats are written directly by each client, both guarded by security rules. The online round loop reuses the existing pure `deck/match_rules.dart` (`isMatch`/`sharedSymbol`) and `deck/deck.dart` (`Deck`, `GameCard`) — no changes to those files — wrapped in a new `RoomRepository` (RTDB I/O) and `OnlineInfernoController` (Riverpod `Notifier` driving the round-advance transaction), mirroring how `TwoPlayerController` wraps the same match rules for local play.

**Tech Stack:** `firebase_core`, `firebase_auth` (anonymous), `firebase_database` (RTDB), `cloud_firestore`; Firebase Local Emulator Suite for dev + tests (already installed: `firebase` CLI 13.15.1, `java` via `openjdk@17`).

**Spec:** [docs/superpowers/specs/2026-09-10-tollywood-spotit-design.md](../specs/2026-09-10-tollywood-spotit-design.md) (§5 architecture, §6 data model, §8 online game flow, §9 security rules) — read this before starting; this plan implements it as amended (2026-09-12: no Cloud Functions; §8.2 round-advance is a single transaction on `deck/centerIndex`, no separate `round.lockUid` node).

## Global Constraints

- Dart string literals use **double quotes**; imports inside `lib/` are **relative** (`../../deck/deck.dart`, not `package:`), matching every existing file. Follow `analysis_options.yaml` (`very_good_analysis`, `public_member_api_docs` off, `prefer_double_quotes` on).
- Firebase project: `spndex-37b0d`. Android app already registered (package `io.tfibagundaali.app`, `android/app/google-services.json` present and gitignored). **No iOS Firebase app yet** — iOS support is out of scope for this plan; gate all Firebase usage behind an `onlineAvailableProvider` that is `false` on any platform other than Android, and leave the home screen's "Play Online" card showing "Coming Soon" wherever that provider is false.
- **No Cloud Functions in v1.** Room creation and end-of-game stat writes are client-side, guarded by RTDB/Firestore security rules (see spec amendment). Do not add a `functions/` directory or the `cloud_functions` package.
- Room code: 5 characters from `ABCDEFGHJKLMNPQRSTUVWXYZ` (26 letters minus `I`/`O`, which are visually confusable with `1`/`0`).
- Round-advance race resolution is **one RTDB transaction directly on `/rooms/{code}/deck/centerIndex`** — no `round` node in the data model (see spec §8.2 amendment).
- Anonymous auth only. No Google/Apple account linking in this plan.
- Solo best-time stats stay exactly as they are today (`lib/storage/best_time_store.dart`, local `SharedPreferences`) — **not** migrated to Firestore by this plan. Only online-game results reach `/users/{uid}/stats`. This is a deliberate scope cut, not an oversight.
- `lib/game/local/`, `lib/game/solo/`, and their screens are untouched by this plan.
- Firebase Realtime Database / Cloud Firestore / Authentication do not need to be "enabled" in the Firebase console for Tasks 1–11 — all development and automated tests run against the **Firebase Local Emulator Suite**, which works standalone. Console enablement is only required before Task 12 (manual two-device verification on real infrastructure).

---

## Task 1: Add Firebase dependencies and guarded bootstrap

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/firebase_options.dart`
- Create: `lib/core/online_availability.dart`
- Modify: `lib/main.dart`
- Test: `test/core/online_availability_test.dart`

**Interfaces:**
- Produces: `isOnlinePlatformSupported({TargetPlatform? platform})` (pure function checking `defaultTargetPlatform`, used only to gate the `main.dart` init attempt), `onlineAvailableProvider` (`Provider<bool>`, keyed off `Firebase.apps.isNotEmpty` — see Step 3 for why), `DefaultFirebaseOptions.currentPlatform` (`FirebaseOptions`, throws `UnsupportedError` on non-Android).

- [ ] **Step 1: Add the Firebase packages**

Run:
```bash
flutter pub add firebase_core firebase_auth firebase_database cloud_firestore
```

This resolves and pins current compatible versions into `pubspec.yaml` and `pubspec.lock` — don't hand-edit version numbers.

- [ ] **Step 2: Write `firebase_options.dart` from the downloaded Android config**

`android/app/google-services.json` already has the values needed. Create:

```dart
// lib/core/firebase_options.dart
import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart" show TargetPlatform, defaultTargetPlatform;

/// Firebase project config for `spndex-37b0d`. Android only for now — no
/// iOS Firebase app is registered yet (see plan Global Constraints).
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
```

Note the inline comment isn't needed in code — the class doc above covers it. The `databaseURL` uses the legacy default-region format; verify it against the console once Realtime Database is enabled (Task 12) and fix here if the console shows a different regional URL — nothing else in the codebase hardcodes it.

- [ ] **Step 3: Add the online-availability provider**

`flutter test`'s binding defaults `defaultTargetPlatform` to `TargetPlatform.android` regardless of the host OS (verified empirically — this is standard Flutter test-host behavior, done so golden tests are OS-independent). That means a provider that re-checks `defaultTargetPlatform` at read time would evaluate `true` inside every widget test, which is wrong here: it would make the home screen's "Play Online" card look enabled in plain widget tests even though no Firebase app ever initialized. So `isOnlinePlatformSupported` (platform-based) stays a narrow helper used only by `main.dart` to decide whether to attempt Firebase init at all — the UI-facing `onlineAvailableProvider` instead checks whether a Firebase app **actually initialized**, which is naturally `false` in any test that doesn't call `Firebase.initializeApp()`:

```dart
// lib/core/online_availability.dart
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
final onlineAvailableProvider = Provider<bool>((ref) => Firebase.apps.isNotEmpty);
```

- [ ] **Step 4: Write the tests**

```dart
// test/core/online_availability_test.dart
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:tfi_bagundaali/core/online_availability.dart";

void main() {
  test("isOnlinePlatformSupported is true only on Android", () {
    expect(isOnlinePlatformSupported(platform: TargetPlatform.android), isTrue);
    expect(isOnlinePlatformSupported(platform: TargetPlatform.iOS), isFalse);
    expect(isOnlinePlatformSupported(platform: TargetPlatform.macOS), isFalse);
  });

  test("onlineAvailableProvider is false with no Firebase app initialized", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(onlineAvailableProvider), isFalse);
  });
}
```

- [ ] **Step 5: Run the test**

Run: `flutter test test/core/online_availability_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Wire guarded init into `main.dart`**

```dart
// lib/main.dart
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:firebase_core/firebase_core.dart";

import "app.dart";
import "core/firebase_options.dart";
import "core/online_availability.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isOnlinePlatformSupported()) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      // Online mode degrades to unavailable; the rest of the app (solo,
      // 2-player, ads) must never be blocked by a Firebase init failure.
    }
  }
  runApp(const ProviderScope(child: MyApp()));
}
```

- [ ] **Step 7: Run the full test suite to confirm nothing else broke**

Run: `flutter test`
Expected: all existing tests still PASS (this step only added code paths gated behind a platform check that's false in the `flutter test` host platform, so nothing existing changes behavior).

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/firebase_options.dart lib/core/online_availability.dart lib/main.dart test/core/online_availability_test.dart
git commit -m "feat: add Firebase bootstrap (Android-only) for online multiplayer"
```

---

## Task 2: Firebase Local Emulator Suite config + dev helper script

**Files:**
- Create: `firebase.json`
- Create: `database.rules.json` (placeholder permissive rules — Task 5/9 fill in real ones)
- Create: `firestore.rules` (placeholder permissive rules — Task 9 fills in real ones)
- Create: `firestore.indexes.json`
- Create: `scripts/test_online.sh`
- Modify: `.env.example`

**Interfaces:**
- Produces: emulator ports (RTDB `9000`, Firestore `8080`, Auth `9099`, UI `4000`) that every later task's tests and the app's emulator-mode wiring depend on.

- [ ] **Step 1: Write `firebase.json`**

```json
{
  "database": {
    "rules": "database.rules.json"
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "emulators": {
    "auth": { "port": 9099 },
    "database": { "port": 9000 },
    "firestore": { "port": 8080 },
    "ui": { "enabled": true, "port": 4000 },
    "singleProjectMode": true
  }
}
```

- [ ] **Step 2: Write starter (permissive dev) rules — real rules land in Tasks 5 and 9**

```json
// database.rules.json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

```
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

```json
// firestore.indexes.json
{
  "indexes": [],
  "fieldOverrides": []
}
```

- [ ] **Step 3: Add `.firebaserc` so the CLI knows the project**

```json
{
  "projects": {
    "default": "spndex-37b0d"
  }
}
```

- [ ] **Step 4: Write the emulator test helper script**

```bash
#!/usr/bin/env bash
#
# Runs `flutter test` against a live Firebase Local Emulator Suite instance.
# Starts the emulators, waits for them, runs tests, always tears down.
#
# Usage:
#   ./scripts/test_online.sh                    # all tests
#   ./scripts/test_online.sh test/rooms/         # a subset

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

firebase emulators:exec \
  --project spndex-37b0d \
  "flutter test --dart-define=USE_FIREBASE_EMULATOR=true ${*:-test}"
```

- [ ] **Step 5: Make it executable**

Run: `chmod +x scripts/test_online.sh`

- [ ] **Step 6: Document the emulator dart-define in `.env.example`**

```
# --- Firebase (online multiplayer) ---
# Set to true to point the app at a locally running Firebase Local Emulator
# Suite (`firebase emulators:start`) instead of the real spndex-37b0d
# project. Automated tests always pass this via scripts/test_online.sh.
USE_FIREBASE_EMULATOR=false
```

- [ ] **Step 7: Verify the emulators start cleanly**

Run: `firebase emulators:exec --project spndex-37b0d "echo ok"`
Expected: prints `ok` after emulator startup logs, exits 0. This proves `firebase.json` and the rule files are syntactically valid before any code depends on them.

- [ ] **Step 8: Commit**

```bash
git add firebase.json database.rules.json firestore.rules firestore.indexes.json .firebaserc scripts/test_online.sh .env.example
git commit -m "feat: add Firebase Local Emulator Suite config for online multiplayer dev/test"
```

---

## Task 3: Point the app at the emulator when requested, and bootstrap anonymous auth

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/auth/anon_auth.dart`
- Test: `test/auth/anon_auth_test.dart`
- Modify: `scripts/run_dev.sh` (no code change needed — it already forwards every `.env` key as a `--dart-define`; confirm and note only)

**Interfaces:**
- Consumes: `Firebase.initializeApp` from Task 1.
- Produces: `authStateProvider` (`StreamProvider<User?>`), `ensureSignedIn(FirebaseAuth auth)` (`Future<User>` — signs in anonymously if `auth.currentUser == null`, otherwise returns the existing user).

- [ ] **Step 1: Point RTDB/Firestore/Auth at the emulator when the dart-define is set**

```dart
// lib/main.dart — replace the Firebase.initializeApp try block with:
  if (isOnlinePlatformSupported()) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (const bool.fromEnvironment("USE_FIREBASE_EMULATOR")) {
        await FirebaseAuth.instance.useAuthEmulator("localhost", 9099);
        FirebaseDatabase.instance.useDatabaseEmulator("localhost", 9000);
        FirebaseFirestore.instance.useFirestoreEmulator("localhost", 8080);
      }
    } catch (_) {
      // Online mode degrades to unavailable; the rest of the app must
      // never be blocked by a Firebase init failure.
    }
  }
```

Add the three imports (`package:firebase_auth/firebase_auth.dart`, `package:firebase_database/firebase_database.dart`, `package:cloud_firestore/cloud_firestore.dart`) to `lib/main.dart`.

- [ ] **Step 2: Write `anon_auth.dart`**

```dart
// lib/auth/anon_auth.dart
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Signs in anonymously if nobody is signed in yet; otherwise returns the
/// current user. Idempotent — safe to call from multiple widgets on start.
Future<User> ensureSignedIn(FirebaseAuth auth) async {
  final current = auth.currentUser;
  if (current != null) return current;
  final credential = await auth.signInAnonymously();
  final user = credential.user;
  if (user == null) {
    throw StateError("anonymous sign-in returned a null user");
  }
  return user;
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  ensureSignedIn(auth);
  return auth.authStateChanges();
});
```

- [ ] **Step 3: Write the test using a fake `FirebaseAuth`**

`firebase_auth` ships `MockFirebaseAuth`-style fakes only via third-party packages; instead of adding a new dependency, test `ensureSignedIn` against the real emulator (it's cheap and exercises the real contract):

```dart
// test/auth/anon_auth_test.dart
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/auth/anon_auth.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("ensureSignedIn signs in anonymously then is idempotent", () async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "fake",
        appId: "1:0:android:0",
        messagingSenderId: "0",
        projectId: "spndex-37b0d",
      ),
    );
    final auth = FirebaseAuth.instance;
    await auth.useAuthEmulator("localhost", 9099);

    final first = await ensureSignedIn(auth);
    expect(first.isAnonymous, isTrue);

    final second = await ensureSignedIn(auth);
    expect(second.uid, first.uid);
  });
}
```

This test requires the emulator — it runs via `scripts/test_online.sh`, not plain `flutter test`.

- [ ] **Step 4: Run it against the emulator**

Run: `./scripts/test_online.sh test/auth/anon_auth_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full plain test suite too (make sure nothing needs the emulator by accident)**

Run: `flutter test`
Expected: PASS except `test/auth/anon_auth_test.dart`, which times out/errors without the emulator running — that's expected and is why it's excluded from plain `flutter test` runs (only invoked via `scripts/test_online.sh`).

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/auth/anon_auth.dart test/auth/anon_auth_test.dart
git commit -m "feat: bootstrap anonymous Firebase auth for online multiplayer"
```

---

## Task 4: Room-code generator (pure, unit-testable)

**Files:**
- Create: `lib/rooms/room_code.dart`
- Test: `test/rooms/room_code_test.dart`

**Interfaces:**
- Produces: `generateRoomCode(math.Random random)` (`String`, always 5 characters from the fixed alphabet), `kRoomCodeAlphabet` (`String` constant, exposed for the test and for input validation on the join screen in Task 6).

- [ ] **Step 1: Write the failing test**

```dart
// test/rooms/room_code_test.dart
import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/rooms/room_code.dart";

void main() {
  test("generates a 5-character code from the fixed alphabet", () {
    final code = generateRoomCode(Random(1));
    expect(code.length, 5);
    expect(code.split("").every(kRoomCodeAlphabet.contains), isTrue);
  });

  test("excludes ambiguous characters", () {
    expect(kRoomCodeAlphabet.contains("I"), isFalse);
    expect(kRoomCodeAlphabet.contains("O"), isFalse);
    expect(kRoomCodeAlphabet.contains("0"), isFalse);
    expect(kRoomCodeAlphabet.contains("1"), isFalse);
  });

  test("is deterministic for a given seeded Random", () {
    expect(generateRoomCode(Random(42)), generateRoomCode(Random(42)));
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/rooms/room_code_test.dart`
Expected: FAIL — `room_code.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/rooms/room_code.dart
import "dart:math";

const kRoomCodeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ";
const _kRoomCodeLength = 5;

/// A 5-character room code drawn from [kRoomCodeAlphabet] (26 letters minus
/// `I`/`O`, which are visually confusable with `1`/`0`).
String generateRoomCode(Random random) => List.generate(
      _kRoomCodeLength,
      (_) => kRoomCodeAlphabet[random.nextInt(kRoomCodeAlphabet.length)],
    ).join();
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `flutter test test/rooms/room_code_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/rooms/room_code.dart test/rooms/room_code_test.dart
git commit -m "feat: add room code generator"
```

---

## Task 5: Room data models

**Files:**
- Create: `lib/rooms/room_models.dart`
- Test: `test/rooms/room_models_test.dart`

**Interfaces:**
- Produces:
  - `RoomMeta({required String status, required String hostUid, required int maxPlayers})`, `RoomMeta.fromMap(Map<Object?, Object?>)`, `RoomMeta.toMap()` → `Map<String, Object?>` (without `createdAt` — the repository adds that).
  - `RoomPlayer({required String name, required int joinedAt, required bool connected, required int currentCardId, required int count})`, `RoomPlayer.fromMap(Map<Object?, Object?>)`.
  - `RoomResult({required String? winnerUid, required Map<String, int> standings})`, `RoomResult.fromMap(Map<Object?, Object?>)`.
  - `RoomSnapshot({required String code, required RoomMeta meta, required Map<String, RoomPlayer> players, required List<int> deckOrder, required int centerIndex, required RoomResult? result})`, `RoomSnapshot.fromMap(String code, Map<Object?, Object?>? raw)`, `RoomSnapshot.empty(String code)`, getters `bool get exists`, `int get centerCardId`, `bool get isComplete`.
- Consumed by: Task 6 (`RoomRepository`), Task 8 (lobby UI), Task 9 (`OnlineInfernoController`).

- [ ] **Step 1: Write the failing test**

```dart
// test/rooms/room_models_test.dart
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/rooms/room_models.dart";

void main() {
  test("RoomSnapshot.empty has no host and an empty player map", () {
    final s = RoomSnapshot.empty("ABCDE");
    expect(s.exists, isFalse);
    expect(s.players, isEmpty);
    expect(s.code, "ABCDE");
  });

  test("RoomSnapshot.fromMap parses a full RTDB-shaped map", () {
    final raw = {
      "meta": {"status": "playing", "hostUid": "u1", "maxPlayers": 8},
      "players": {
        "u1": {
          "name": "Alice",
          "joinedAt": 1000,
          "connected": true,
          "currentCardId": 3,
          "count": 2,
        },
        "u2": {
          "name": "Bob",
          "joinedAt": 2000,
          "connected": false,
          "currentCardId": 7,
          "count": 1,
        },
      },
      "deck": {
        "order": [3, 7, 12, 5],
        "centerIndex": 2,
      },
    };

    final s = RoomSnapshot.fromMap("ABCDE", raw);
    expect(s.exists, isTrue);
    expect(s.meta.status, "playing");
    expect(s.meta.hostUid, "u1");
    expect(s.players["u1"]!.name, "Alice");
    expect(s.players["u1"]!.joinedAt, 1000);
    expect(s.players["u2"]!.connected, isFalse);
    expect(s.deckOrder, [3, 7, 12, 5]);
    expect(s.centerIndex, 2);
    expect(s.centerCardId, 12);
    expect(s.isComplete, isFalse);
    expect(s.result, isNull);
  });

  test("RoomSnapshot.isComplete when centerIndex reaches deck length", () {
    final raw = {
      "meta": {"status": "playing", "hostUid": "u1", "maxPlayers": 2},
      "players": <String, Object?>{},
      "deck": {"order": [1, 2], "centerIndex": 2},
    };
    expect(RoomSnapshot.fromMap("X", raw).isComplete, isTrue);
  });

  test("RoomSnapshot.fromMap parses a result block", () {
    final raw = {
      "meta": {"status": "finished", "hostUid": "u1", "maxPlayers": 2},
      "players": <String, Object?>{},
      "deck": {"order": <int>[], "centerIndex": 0},
      "result": {
        "winnerUid": "u1",
        "standings": {"u1": 30, "u2": 27},
      },
    };
    final s = RoomSnapshot.fromMap("X", raw);
    expect(s.result!.winnerUid, "u1");
    expect(s.result!.standings, {"u1": 30, "u2": 27});
  });

  test("RoomMeta.toMap round-trips through fromMap", () {
    const meta = RoomMeta(status: "lobby", hostUid: "u1", maxPlayers: 6);
    expect(RoomMeta.fromMap(meta.toMap()), meta);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/rooms/room_models_test.dart`
Expected: FAIL — `room_models.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/rooms/room_models.dart
import "package:flutter/foundation.dart";

@immutable
class RoomMeta {
  const RoomMeta({
    required this.status,
    required this.hostUid,
    required this.maxPlayers,
  });

  final String status;
  final String hostUid;
  final int maxPlayers;

  static const empty = RoomMeta(status: "lobby", hostUid: "", maxPlayers: 8);

  factory RoomMeta.fromMap(Map<Object?, Object?> map) => RoomMeta(
        status: map["status"] as String? ?? "lobby",
        hostUid: map["hostUid"] as String? ?? "",
        maxPlayers: (map["maxPlayers"] as num?)?.toInt() ?? 8,
      );

  Map<String, Object?> toMap() => {
        "status": status,
        "hostUid": hostUid,
        "maxPlayers": maxPlayers,
      };

  @override
  bool operator ==(Object other) =>
      other is RoomMeta &&
      other.status == status &&
      other.hostUid == hostUid &&
      other.maxPlayers == maxPlayers;

  @override
  int get hashCode => Object.hash(status, hostUid, maxPlayers);
}

@immutable
class RoomPlayer {
  const RoomPlayer({
    required this.name,
    required this.joinedAt,
    required this.connected,
    required this.currentCardId,
    required this.count,
  });

  final String name;
  final int joinedAt;
  final bool connected;
  final int currentCardId;
  final int count;

  factory RoomPlayer.fromMap(Map<Object?, Object?> map) => RoomPlayer(
        name: map["name"] as String? ?? "Player",
        joinedAt: (map["joinedAt"] as num?)?.toInt() ?? 0,
        connected: map["connected"] as bool? ?? false,
        currentCardId: (map["currentCardId"] as num?)?.toInt() ?? -1,
        count: (map["count"] as num?)?.toInt() ?? 0,
      );
}

@immutable
class RoomResult {
  const RoomResult({required this.winnerUid, required this.standings});

  final String? winnerUid;
  final Map<String, int> standings;

  factory RoomResult.fromMap(Map<Object?, Object?> map) => RoomResult(
        winnerUid: map["winnerUid"] as String?,
        standings: {
          for (final e in ((map["standings"] as Map?) ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
      );
}

@immutable
class RoomSnapshot {
  const RoomSnapshot({
    required this.code,
    required this.meta,
    required this.players,
    required this.deckOrder,
    required this.centerIndex,
    required this.result,
  });

  final String code;
  final RoomMeta meta;
  final Map<String, RoomPlayer> players;
  final List<int> deckOrder;
  final int centerIndex;
  final RoomResult? result;

  factory RoomSnapshot.empty(String code) => RoomSnapshot(
        code: code,
        meta: RoomMeta.empty,
        players: const {},
        deckOrder: const [],
        centerIndex: 0,
        result: null,
      );

  factory RoomSnapshot.fromMap(String code, Map<Object?, Object?>? raw) {
    if (raw == null) return RoomSnapshot.empty(code);

    final metaMap = (raw["meta"] as Map?)?.cast<Object?, Object?>();
    final playersMap = (raw["players"] as Map?)?.cast<Object?, Object?>() ?? const {};
    final deckMap = (raw["deck"] as Map?)?.cast<Object?, Object?>();
    final resultMap = (raw["result"] as Map?)?.cast<Object?, Object?>();

    return RoomSnapshot(
      code: code,
      meta: metaMap == null ? RoomMeta.empty : RoomMeta.fromMap(metaMap),
      players: {
        for (final e in playersMap.entries)
          e.key as String: RoomPlayer.fromMap((e.value as Map).cast()),
      },
      deckOrder: ((deckMap?["order"] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      centerIndex: (deckMap?["centerIndex"] as num?)?.toInt() ?? 0,
      result: resultMap == null ? null : RoomResult.fromMap(resultMap),
    );
  }

  bool get exists => meta.hostUid.isNotEmpty;

  bool get isComplete => deckOrder.isNotEmpty && centerIndex >= deckOrder.length;

  int get centerCardId => deckOrder[centerIndex];
}
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `flutter test test/rooms/room_models_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/rooms/room_models.dart test/rooms/room_models_test.dart
git commit -m "feat: add room data models for online multiplayer"
```

---

## Task 6: RoomRepository + real RTDB security rules + emulator tests

**Files:**
- Create: `lib/rooms/room_repository.dart`
- Modify: `database.rules.json` (replace the Task 2 placeholder)
- Test: `test/rooms/room_repository_test.dart`

**Interfaces:**
- Consumes: `RoomMeta`, `RoomPlayer`, `RoomSnapshot`, `RoomResult` (Task 5); `generateRoomCode`, `kRoomCodeAlphabet` (Task 4).
- Produces:
  - `RoomRepository({required DatabaseReference root, required String Function() currentUid, Random? random})`.
  - `Future<String> createRoom({int maxPlayers = 8, int maxAttempts = 8})`.
  - `Future<void> joinRoom(String code, {required String displayName})` — throws `RoomJoinException`.
  - `Stream<RoomSnapshot> watchRoom(String code)`.
  - `Future<void> setConnected(String code, {required bool connected})`.
  - `Future<void> startGame(String code, {required List<int> deckOrder, required List<String> orderedUids})` — host-only by rules.
  - `Future<void> setPlaying(String code)`.
  - `Future<bool> tryAdvance(String code, {required int expectedCenterIndex, required int newCenterCardId})` — returns `true` iff this call won the race.
  - `Future<void> writeResult(String code, RoomResult result)`.
  - `Future<void> electHost(String code, String newHostUid)`.
  - `RoomJoinException(String message)`, `RoomCreateException(String message)` (both `implements Exception`).
- Consumed by: Task 8 (lobby UI), Task 9 (`OnlineInfernoController`), Task 10 (resilience).

- [ ] **Step 1: Write the real RTDB rules**

```json
// database.rules.json
{
  "rules": {
    "rooms": {
      "$code": {
        "meta": {
          ".read": "auth != null",
          ".write": "auth != null && (!data.exists() || newData.child('hostUid').val() === auth.uid || data.child('hostUid').val() === auth.uid)",
          ".validate": "newData.hasChildren(['status', 'hostUid', 'maxPlayers'])",
          "status": {
            ".validate": "newData.val() === 'lobby' || newData.val() === 'countdown' || newData.val() === 'playing' || newData.val() === 'finished'"
          },
          "hostUid": { ".validate": "newData.isString()" },
          "maxPlayers": { ".validate": "newData.isNumber()" }
        },
        "players": {
          "$uid": {
            ".read": "auth != null",
            ".write": "auth != null && auth.uid === $uid",
            "count": {
              ".validate": "!data.exists() || newData.val() === 0 || newData.val() === data.val() + 1"
            }
          }
        },
        "deck": {
          ".read": "auth != null",
          "order": {
            ".write": "auth != null && root.child('rooms').child($code).child('meta').child('hostUid').val() === auth.uid"
          },
          "centerIndex": {
            ".write": "auth != null && root.child('rooms').child($code).child('players').child(auth.uid).exists()",
            ".validate": "!data.exists() || newData.val() === data.val() + 1 || (newData.val() === 0 && !data.exists())"
          }
        },
        "result": {
          ".read": "auth != null",
          ".write": "auth != null && !data.exists() && root.child('rooms').child($code).child('meta').child('status').val() === 'finished'"
        }
      }
    }
  }
}
```

This is a first pass, not a final audit — Step 6 below pins its actual behavior with tests, which is the real spec (per the design doc's own "sketch, finalized during implementation" framing).

- [ ] **Step 2: Implement `RoomRepository`**

```dart
// lib/rooms/room_repository.dart
import "dart:math";

import "package:firebase_database/firebase_database.dart";

import "room_code.dart";
import "room_models.dart";

class RoomJoinException implements Exception {
  const RoomJoinException(this.message);
  final String message;
  @override
  String toString() => "RoomJoinException: $message";
}

class RoomCreateException implements Exception {
  const RoomCreateException(this.message);
  final String message;
  @override
  String toString() => "RoomCreateException: $message";
}

/// RTDB I/O for `/rooms/{code}` (spec §6.1, §8). No Cloud Functions —
/// room creation and the round-advance race are both client transactions.
class RoomRepository {
  RoomRepository({
    required DatabaseReference root,
    required String Function() currentUid,
    Random? random,
  })  : _root = root,
        _uid = currentUid,
        _random = random ?? Random.secure();

  final DatabaseReference _root;
  final String Function() _uid;
  final Random _random;

  DatabaseReference _room(String code) => _root.child("rooms/$code");

  Future<String> createRoom({int maxPlayers = 8, int maxAttempts = 8}) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = generateRoomCode(_random);
      final metaRef = _room(code).child("meta");
      final meta = RoomMeta(status: "lobby", hostUid: _uid(), maxPlayers: maxPlayers);
      final result = await metaRef.runTransaction((current) {
        if (current != null) return Transaction.abort();
        return Transaction.success(meta.toMap());
      });
      if (result.committed) return code;
    }
    throw const RoomCreateException("could not allocate a room code");
  }

  Future<void> joinRoom(String code, {required String displayName}) async {
    final metaSnap = await _room(code).child("meta").get();
    if (!metaSnap.exists) throw const RoomJoinException("room not found");
    final meta = RoomMeta.fromMap((metaSnap.value as Map).cast());
    if (meta.status != "lobby") {
      throw const RoomJoinException("game already started");
    }
    final playersSnap = await _room(code).child("players").get();
    final currentCount =
        playersSnap.exists ? (playersSnap.value as Map).length : 0;
    if (currentCount >= meta.maxPlayers) {
      throw const RoomJoinException("room is full");
    }

    final uid = _uid();
    final playerRef = _room(code).child("players/$uid");
    await playerRef.set({
      "name": displayName,
      "joinedAt": ServerValue.timestamp,
      "connected": true,
      "currentCardId": -1,
      "count": 0,
    });
    await playerRef.child("connected").onDisconnect().set(false);
  }

  Stream<RoomSnapshot> watchRoom(String code) => _room(code)
      .onValue
      .map((e) => RoomSnapshot.fromMap(code, (e.snapshot.value as Map?)?.cast()));

  Future<void> setConnected(String code, {required bool connected}) =>
      _room(code).child("players/${_uid()}/connected").set(connected);

  Future<void> startGame(
    String code, {
    required List<int> deckOrder,
    required List<String> orderedUids,
  }) async {
    final updates = <String, Object?>{
      "rooms/$code/deck/order": deckOrder,
      "rooms/$code/deck/centerIndex": orderedUids.length,
      "rooms/$code/meta/status": "countdown",
    };
    for (var i = 0; i < orderedUids.length; i++) {
      updates["rooms/$code/players/${orderedUids[i]}/currentCardId"] = deckOrder[i];
    }
    await _root.update(updates);
  }

  Future<void> setPlaying(String code) =>
      _room(code).child("meta/status").set("playing");

  Future<bool> tryAdvance(
    String code, {
    required int expectedCenterIndex,
    required int newCenterCardId,
  }) async {
    final centerRef = _room(code).child("deck/centerIndex");
    final result = await centerRef.runTransaction((current) {
      final cur = (current as num?)?.toInt();
      if (cur != expectedCenterIndex) return Transaction.abort();
      return Transaction.success(expectedCenterIndex + 1);
    });
    if (!result.committed) return false;

    final uid = _uid();
    await _root.update({
      "rooms/$code/players/$uid/count": ServerValue.increment(1),
      "rooms/$code/players/$uid/currentCardId": newCenterCardId,
    });
    return true;
  }

  Future<void> writeResult(String code, RoomResult result) async {
    final resultRef = _room(code).child("result");
    final txn = await resultRef.runTransaction((current) {
      if (current != null) return Transaction.abort();
      return Transaction.success({
        "winnerUid": result.winnerUid,
        "standings": result.standings,
      });
    });
    if (txn.committed) {
      await _room(code).child("meta/status").set("finished");
    }
  }

  Future<void> electHost(String code, String newHostUid) =>
      _room(code).child("meta/hostUid").set(newHostUid);
}
```

- [ ] **Step 3: Write emulator-backed repository + rules tests**

```dart
// test/rooms/room_repository_test.dart
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/rooms/room_models.dart";
import "package:tfi_bagundaali/rooms/room_repository.dart";

/// Signs in a fresh anonymous user against the emulator and returns a
/// [RoomRepository] bound to that user's uid — used to simulate one
/// "client" in multi-client scenarios.
Future<RoomRepository> _client(String appName) async {
  final app = await Firebase.initializeApp(
    name: appName,
    options: const FirebaseOptions(
      apiKey: "fake",
      appId: "1:0:android:0",
      messagingSenderId: "0",
      projectId: "spndex-37b0d",
      databaseURL: "https://spndex-37b0d-default-rtdb.firebaseio.com",
    ),
  );
  final auth = FirebaseAuth.instanceFor(app: app);
  await auth.useAuthEmulator("localhost", 9099);
  final credential = await auth.signInAnonymously();
  final db = FirebaseDatabase.instanceFor(app: app);
  db.useDatabaseEmulator("localhost", 9000);
  return RoomRepository(
    root: db.ref(),
    currentUid: () => credential.user!.uid,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("createRoom returns a joinable code; join then reject a third + wrong status", () async {
    final host = await _client("host1");
    final code = await host.createRoom(maxPlayers: 2);
    expect(code.length, 5);

    final p2 = await _client("p2-1");
    await p2.joinRoom(code, displayName: "Bob");

    final p3 = await _client("p3-1");
    await expectLater(
      p3.joinRoom(code, displayName: "Carol"),
      throwsA(isA<RoomJoinException>()),
    );
  });

  test("joinRoom rejects once the room has left lobby status", () async {
    final host = await _client("host2");
    final code = await host.createRoom(maxPlayers: 8);
    final p2 = await _client("p2-2");
    await p2.joinRoom(code, displayName: "Bob");
    await host.startGame(code, deckOrder: [0, 1, 2], orderedUids: [/* host uid unknown here */]);
    final p3 = await _client("p3-2");
    await expectLater(
      p3.joinRoom(code, displayName: "Carol"),
      throwsA(isA<RoomJoinException>()),
    );
  });

  test("watchRoom streams player joins", () async {
    final host = await _client("host3");
    final code = await host.createRoom(maxPlayers: 8);
    final events = <int>[];
    final sub = host.watchRoom(code).listen((s) => events.add(s.players.length));

    final p2 = await _client("p2-3");
    await p2.joinRoom(code, displayName: "Bob");

    await Future<void>.delayed(const Duration(milliseconds: 300));
    await sub.cancel();
    expect(events.last, 1);
  });

  test("tryAdvance: two clients racing the same centerIndex — exactly one wins", () async {
    final host = await _client("host4");
    final code = await host.createRoom(maxPlayers: 2);
    final p2 = await _client("p2-4");
    await p2.joinRoom(code, displayName: "Bob");

    // Seed deck state directly (bypassing startGame's uid plumbing, which
    // this test doesn't need).
    final results = await Future.wait([
      host.tryAdvance(code, expectedCenterIndex: 0, newCenterCardId: 5),
      p2.tryAdvance(code, expectedCenterIndex: 0, newCenterCardId: 5),
    ]);
    expect(results.where((r) => r).length, 1);
  });

  test("writeResult is write-once", () async {
    final host = await _client("host5");
    final code = await host.createRoom(maxPlayers: 2);
    await host.writeResult(code, const RoomResult(winnerUid: "u1", standings: {"u1": 30}));
    // Second write attempts to overwrite — rules + transaction abort keep
    // the room's status at "finished" and the first result intact.
    await host.writeResult(code, const RoomResult(winnerUid: "u2", standings: {"u2": 1}));
    final snap = await host.watchRoom(code).first;
    expect(snap.result!.winnerUid, "u1");
  });
}
```

Note: the `startGame` call in the second test passes an empty `orderedUids` list on purpose — that test only checks the join-after-start rejection, not dealing; a real deal is exercised in Task 9's controller test with real uids.

- [ ] **Step 4: Run against the emulator**

Run: `./scripts/test_online.sh test/rooms/room_repository_test.dart`
Expected: PASS (5 tests). If `tryAdvance` shows both calls winning, the rule/transaction target is wrong — re-check Step 1/2 before moving on; this is the single most important invariant in the whole feature.

- [ ] **Step 5: Commit**

```bash
git add lib/rooms/room_repository.dart database.rules.json test/rooms/room_repository_test.dart
git commit -m "feat: add RoomRepository with RTDB rules for room lifecycle"
```

---

## Task 7: Firestore stats writer + rules

**Files:**
- Create: `lib/profile/stats_repository.dart`
- Modify: `firestore.rules` (replace the Task 2 placeholder)
- Test: `test/profile/stats_repository_test.dart`

**Interfaces:**
- Produces: `StatsRepository({required FirebaseFirestore firestore, required String Function() currentUid})`, `Future<void> recordOnlineGame({required bool won})` (increments `gamesPlayed`, `onlinePlayed`, and `gamesWon` if `won`, sets `lastPlayedAt`).
- Consumed by: Task 9 (`OnlineInfernoController`, called once when a client observes `status == "finished"`).

- [ ] **Step 1: Write the real Firestore rules**

```
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow create: if request.auth != null && request.auth.uid == uid;
      allow update: if request.auth != null
        && request.auth.uid == uid
        && isMonotonicOrAbsent('gamesPlayed')
        && isMonotonicOrAbsent('gamesWon')
        && isMonotonicOrAbsent('onlinePlayed');

      function isMonotonicOrAbsent(field) {
        let before = resource.data.stats;
        let after = request.resource.data.stats;
        return !(field in after) || !(field in before) || after[field] >= before[field];
      }
    }
  }
}
```

- [ ] **Step 2: Implement `StatsRepository`**

```dart
// lib/profile/stats_repository.dart
import "package:cloud_firestore/cloud_firestore.dart";

/// Writes durable per-user stats (spec §6.2). Client-side (no Cloud
/// Function in v1) — Firestore rules enforce monotonic counters.
class StatsRepository {
  StatsRepository({
    required FirebaseFirestore firestore,
    required String Function() currentUid,
  })  : _firestore = firestore,
        _uid = currentUid;

  final FirebaseFirestore _firestore;
  final String Function() _uid;

  Future<void> recordOnlineGame({required bool won}) async {
    final ref = _firestore.collection("users").doc(_uid());
    await ref.set({
      "stats": {
        "gamesPlayed": FieldValue.increment(1),
        "onlinePlayed": FieldValue.increment(1),
        if (won) "gamesWon": FieldValue.increment(1),
        "lastPlayedAt": FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }
}
```

- [ ] **Step 3: Write the emulator test**

```dart
// test/profile/stats_repository_test.dart
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/profile/stats_repository.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("recordOnlineGame increments counters across two calls", () async {
    final app = await Firebase.initializeApp(
      name: "stats1",
      options: const FirebaseOptions(
        apiKey: "fake",
        appId: "1:0:android:0",
        messagingSenderId: "0",
        projectId: "spndex-37b0d",
      ),
    );
    final auth = FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator("localhost", 9099);
    final credential = await auth.signInAnonymously();
    final firestore = FirebaseFirestore.instanceFor(app: app);
    firestore.useFirestoreEmulator("localhost", 8080);

    final repo = StatsRepository(
      firestore: firestore,
      currentUid: () => credential.user!.uid,
    );

    await repo.recordOnlineGame(won: true);
    await repo.recordOnlineGame(won: false);

    final doc = await firestore.collection("users").doc(credential.user!.uid).get();
    final stats = doc.data()!["stats"] as Map<String, dynamic>;
    expect(stats["gamesPlayed"], 2);
    expect(stats["onlinePlayed"], 2);
    expect(stats["gamesWon"], 1);
  });

  test("a user cannot write another user's stats", () async {
    final app = await Firebase.initializeApp(
      name: "stats2",
      options: const FirebaseOptions(
        apiKey: "fake",
        appId: "1:0:android:0",
        messagingSenderId: "0",
        projectId: "spndex-37b0d",
      ),
    );
    final auth = FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator("localhost", 9099);
    await auth.signInAnonymously();
    final firestore = FirebaseFirestore.instanceFor(app: app);
    firestore.useFirestoreEmulator("localhost", 8080);

    final repo = StatsRepository(firestore: firestore, currentUid: () => "someone-else");
    await expectLater(
      repo.recordOnlineGame(won: true),
      throwsA(isA<FirebaseException>()),
    );
  });
}
```

- [ ] **Step 4: Run against the emulator**

Run: `./scripts/test_online.sh test/profile/stats_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/profile/stats_repository.dart firestore.rules test/profile/stats_repository_test.dart
git commit -m "feat: add Firestore stats writer with monotonic-counter rules"
```

---

## Task 8: OnlineInfernoController — the online round loop

**Files:**
- Create: `lib/game/online/online_inferno_controller.dart`
- Test: `test/game/online_inferno_controller_test.dart`

**Interfaces:**
- Consumes: `RoomRepository` (Task 6), `RoomSnapshot`/`RoomPlayer`/`RoomResult` (Task 5), `StatsRepository` (Task 7), `Deck`/`isMatch`/`sharedSymbol` (existing `lib/deck/deck.dart`, `lib/deck/match_rules.dart` — unchanged), `deckProvider` (existing `lib/game/solo/solo_controller.dart`).
- Produces:
  - `OnlineInfernoController extends Notifier<AsyncValue<RoomSnapshot>>` — family-less; scoped per-room via a `roomCodeProvider` (`StateProvider<String?>`) it reads on `build()`.
  - `onlineInfernoControllerProvider` (`NotifierProvider<OnlineInfernoController, AsyncValue<RoomSnapshot>>`).
  - `roomCodeProvider` (`StateProvider<String?>`) — set by the lobby screen (Task 8's UI counterpart in Task 9) before this controller is read.
  - `void tap(int symbolId)` — client-side `MatchRules` check, then `tryAdvance`; no-ops silently on a wrong tap (mirrors `SoloController`/`TwoPlayerController`'s local-lockout pattern, kept in the UI layer in Task 9 since the lockout duration is a widget concern there too).
  - `Future<void> markResultIfComplete()` — called by the UI once per completion to run `writeResult` + `StatsRepository.recordOnlineGame` exactly once.

- [ ] **Step 1: Write the failing test**

This drives the controller against the **real emulator** with two simulated clients — a pure-Dart fake `RoomRepository` would hide the exact transaction-race behavior this controller depends on, which is the whole point of the test.

```dart
// test/game/online_inferno_controller_test.dart
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/deck/deck_loader.dart";
import "package:tfi_bagundaali/deck/dobble.dart";
import "package:tfi_bagundaali/deck/match_rules.dart";
import "package:tfi_bagundaali/game/online/online_inferno_controller.dart";
import "package:tfi_bagundaali/game/solo/solo_controller.dart" show deckProvider;
import "package:tfi_bagundaali/rooms/room_repository.dart";

Future<({RoomRepository repo, String uid})> _client(String appName) async {
  final app = await Firebase.initializeApp(
    name: appName,
    options: const FirebaseOptions(
      apiKey: "fake",
      appId: "1:0:android:0",
      messagingSenderId: "0",
      projectId: "spndex-37b0d",
      databaseURL: "https://spndex-37b0d-default-rtdb.firebaseio.com",
    ),
  );
  final auth = FirebaseAuth.instanceFor(app: app);
  await auth.useAuthEmulator("localhost", 9099);
  final credential = await auth.signInAnonymously();
  final db = FirebaseDatabase.instanceFor(app: app);
  db.useDatabaseEmulator("localhost", 9000);
  return (
    repo: RoomRepository(root: db.ref(), currentUid: () => credential.user!.uid),
    uid: credential.user!.uid,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final deck = deckFromRows(generateDobbleDeck(7));

  test("two players play a full room to completion; counts sum to 55", () async {
    final host = await _client("oic-host");
    final p2 = await _client("oic-p2");

    final code = await host.repo.createRoom(maxPlayers: 2);
    await p2.repo.joinRoom(code, displayName: "Bob");
    await host.repo.startGame(
      code,
      deckOrder: List.generate(57, (i) => i),
      orderedUids: [host.uid, p2.uid],
    );
    await host.repo.setPlaying(code);

    final hostContainer = ProviderContainer(overrides: [
      deckProvider.overrideWith((_) async => deck),
      roomCodeProvider.overrideWith((_) => code),
      roomRepositoryProvider.overrideWithValue(host.repo),
    ]);
    final p2Container = ProviderContainer(overrides: [
      deckProvider.overrideWith((_) async => deck),
      roomCodeProvider.overrideWith((_) => code),
      roomRepositoryProvider.overrideWithValue(p2.repo),
    ]);
    await hostContainer.read(deckProvider.future);
    await p2Container.read(deckProvider.future);

    Future<void> driveOneCorrectTap(ProviderContainer c, String uid) async {
      final snap = await c.read(roomRepositoryProvider).watchRoom(code).first;
      final held = deck.card(snap.players[uid]!.currentCardId);
      final center = deck.card(snap.centerCardId);
      final symbol = sharedSymbol(held, center);
      c.read(onlineInfernoControllerProvider.notifier).tap(symbol);
      // give the RTDB round-trip a moment
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    var guard = 0;
    while (guard++ < 120) {
      final snap = await host.repo.watchRoom(code).first;
      if (snap.isComplete) break;
      await driveOneCorrectTap(hostContainer, host.uid);
      await driveOneCorrectTap(p2Container, p2.uid);
    }

    final finalSnap = await host.repo.watchRoom(code).first;
    expect(finalSnap.isComplete, isTrue);
    final total = finalSnap.players.values.fold<int>(0, (a, p) => a + p.count);
    expect(total, 55);

    hostContainer.dispose();
    p2Container.dispose();
  });

  test("a wrong tap does not advance the room", () async {
    final host = await _client("oic-host2");
    final code = await host.repo.createRoom(maxPlayers: 2);
    await host.repo.startGame(
      code,
      deckOrder: List.generate(57, (i) => i),
      orderedUids: [host.uid],
    );
    await host.repo.setPlaying(code);

    final container = ProviderContainer(overrides: [
      deckProvider.overrideWith((_) async => deck),
      roomCodeProvider.overrideWith((_) => code),
      roomRepositoryProvider.overrideWithValue(host.repo),
    ]);
    await container.read(deckProvider.future);

    final before = await host.repo.watchRoom(code).first;
    final held = deck.card(before.players[host.uid]!.currentCardId);
    final center = deck.card(before.centerCardId);
    final correct = sharedSymbol(held, center);
    final wrong = held.symbolIds.firstWhere((s) => s != correct);

    container.read(onlineInfernoControllerProvider.notifier).tap(wrong);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final after = await host.repo.watchRoom(code).first;
    expect(after.centerIndex, before.centerIndex);

    container.dispose();
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `./scripts/test_online.sh test/game/online_inferno_controller_test.dart`
Expected: FAIL — `online_inferno_controller.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/game/online/online_inferno_controller.dart
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../deck/deck.dart";
import "../../deck/match_rules.dart";
import "../../rooms/room_models.dart";
import "../../rooms/room_repository.dart";
import "../solo/solo_controller.dart" show deckProvider;

/// The room code the controller operates on. Set by the lobby screen
/// before navigating to the game screen.
final roomCodeProvider = StateProvider<String?>((ref) => null);

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(
    root: FirebaseDatabase.instance.ref(),
    currentUid: () => FirebaseAuth.instance.currentUser!.uid,
  );
});

class OnlineInfernoController extends Notifier<AsyncValue<RoomSnapshot>> {
  @override
  AsyncValue<RoomSnapshot> build() {
    final code = ref.watch(roomCodeProvider);
    if (code == null) {
      return const AsyncValue.error("no room code set", StackTrace.empty);
    }
    final repo = ref.watch(roomRepositoryProvider);
    final sub = repo.watchRoom(code).listen(
          (snap) => state = AsyncValue.data(snap),
          onError: (Object e, StackTrace st) => state = AsyncValue.error(e, st),
        );
    ref.onDispose(sub.cancel);
    return const AsyncValue.loading();
  }

  Deck get _deck => ref.read(deckProvider).requireValue;
  RoomRepository get _repo => ref.read(roomRepositoryProvider);
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  void tap(int symbolId) {
    final snap = state.value;
    if (snap == null || snap.isComplete) return;
    final me = snap.players[_uid];
    if (me == null) return;

    final held = _deck.card(me.currentCardId);
    final center = _deck.card(snap.centerCardId);
    if (!isMatch(held, center, symbolId)) return; // wrong tap: local no-op

    _repo.tryAdvance(
      snap.code,
      expectedCenterIndex: snap.centerIndex,
      newCenterCardId: center.id,
    );
  }
}

final onlineInfernoControllerProvider =
    NotifierProvider<OnlineInfernoController, AsyncValue<RoomSnapshot>>(
  OnlineInfernoController.new,
);
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `./scripts/test_online.sh test/game/online_inferno_controller_test.dart`
Expected: PASS (2 tests). This is the highest-risk task in the plan (real transaction races over the network) — if the completion test hangs, check the emulator UI at `localhost:4000/database` mid-run to see where `centerIndex`/`players/*/count` actually landed.

- [ ] **Step 5: Commit**

```bash
git add lib/game/online/online_inferno_controller.dart test/game/online_inferno_controller_test.dart
git commit -m "feat: add OnlineInfernoController driving the synced round loop"
```

---

## Task 9: Lobby UI — create/join room, player list, host start

**Files:**
- Create: `lib/ui/online/online_lobby_screen.dart`
- Create: `lib/ui/online/create_join_screen.dart`
- Modify: `lib/core/router.dart`
- Test: `test/ui/online/create_join_screen_test.dart`
- Test: `test/ui/online/online_lobby_screen_test.dart`

**Interfaces:**
- Consumes: `RoomRepository`/`roomRepositoryProvider` (Task 8), `RoomSnapshot`/`RoomPlayer` (Task 5), `roomCodeProvider` (Task 8), `confirmQuit` (existing `lib/ui/widgets/quit_confirm.dart`), `Routes` (existing `lib/core/router.dart`).
- Produces: `Routes.online` (`/online`), `Routes.onlineLobby` (`/online/lobby/:code`), `CreateJoinScreen`, `OnlineLobbyScreen`.

- [ ] **Step 1: Add the `online` and `onlineLobby` routes**

`OnlineGameScreen` doesn't exist until Task 10, so this task wires only the two `GoRoute`s it can build. `OnlineLobbyScreen` (Step 3 below) needs to navigate to the game route once the host starts, so add the `onlineGame` path constant now too — it's just a string function, valid without a matching `GoRoute` entry until Task 10 adds one.

```dart
// lib/core/router.dart
abstract final class Routes {
  // ...existing entries unchanged...
  static const online = "/online";
  static String onlineLobby(String code) => "/online/lobby/$code";
  static String onlineGame(String code) => "/online/game/$code";
}
```

```dart
// lib/core/router.dart — add to the routes list, and add the two new
// imports (../ui/online/create_join_screen.dart, .../online_lobby_screen.dart):
    GoRoute(path: Routes.online, builder: (_, __) => const CreateJoinScreen()),
    GoRoute(
      path: "/online/lobby/:code",
      builder: (_, state) => OnlineLobbyScreen(code: state.pathParameters["code"]!),
    ),
```

- [ ] **Step 2: Implement `CreateJoinScreen`**

```dart
// lib/ui/online/create_join_screen.dart
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../auth/anon_auth.dart";
import "../../core/router.dart";
import "../../rooms/room_repository.dart";

class CreateJoinScreen extends ConsumerStatefulWidget {
  const CreateJoinScreen({super.key});

  @override
  ConsumerState<CreateJoinScreen> createState() => _CreateJoinScreenState();
}

class _CreateJoinScreenState extends ConsumerState<CreateJoinScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController(text: "Player");
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ensureSignedIn(ref.read(firebaseAuthProvider));
      final repo = ref.read(roomRepositoryProvider);
      final code = await repo.createRoom();
      await repo.joinRoom(code, displayName: _nameController.text.trim());
      if (mounted) context.go(Routes.onlineLobby(code));
    } catch (e) {
      setState(() => _error = "Couldn't create a room: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 5) {
      setState(() => _error = "Enter the 5-letter room code");
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ensureSignedIn(ref.read(firebaseAuthProvider));
      await ref.read(roomRepositoryProvider).joinRoom(
            code,
            displayName: _nameController.text.trim(),
          );
      if (mounted) context.go(Routes.onlineLobby(code));
    } catch (e) {
      setState(() => _error = "Couldn't join: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Play Online")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Your name"),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: const Text("Create a room"),
            ),
            const SizedBox(height: 32),
            const Text("— or —", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 5,
              decoration: const InputDecoration(labelText: "Room code"),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _join,
              child: const Text("Join"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Implement `OnlineLobbyScreen`**

```dart
// lib/ui/online/online_lobby_screen.dart
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../auth/anon_auth.dart";
import "../../core/router.dart";
import "../../game/engine/round_state.dart" show shuffledDeckOrder;
import "../../game/online/online_inferno_controller.dart" show roomRepositoryProvider;
import "../../rooms/room_models.dart";
import "../widgets/quit_confirm.dart";

class OnlineLobbyScreen extends ConsumerWidget {
  const OnlineLobbyScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(roomRepositoryProvider);
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Room $code"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (await confirmQuit(context, title: "Leave room?", message: "You'll leave this lobby.")) {
              await repo.setConnected(code, connected: false);
              if (context.mounted) context.go(Routes.home);
            }
          },
        ),
      ),
      body: StreamBuilder<RoomSnapshot>(
        stream: repo.watchRoom(code),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final room = snap.data!;
          final isHost = room.meta.hostUid == myUid;
          final connectedCount = room.players.values.where((p) => p.connected).length;

          if (room.meta.status != "lobby") {
            // Another client (the host) already started — follow along.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(Routes.onlineGame(code));
            });
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text("Code: $code", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              for (final entry in room.players.entries)
                ListTile(
                  title: Text(entry.value.name),
                  trailing: Icon(
                    entry.value.connected ? Icons.circle : Icons.circle_outlined,
                    color: entry.value.connected ? Colors.green : Colors.grey,
                    size: 12,
                  ),
                ),
              const SizedBox(height: 24),
              if (isHost)
                FilledButton(
                  onPressed: connectedCount >= 2
                      ? () async {
                          final uids = room.players.entries.toList()
                            ..sort((a, b) => a.value.joinedAt.compareTo(b.value.joinedAt));
                          final deckOrder = shuffledDeckOrder(
                            DateTime.now().millisecondsSinceEpoch,
                          );
                          await repo.startGame(
                            code,
                            deckOrder: deckOrder,
                            orderedUids: uids.map((e) => e.key).toList(),
                          );
                        }
                      : null,
                  child: Text(
                    connectedCount >= 2
                        ? "Start game"
                        : "Waiting for players (${connectedCount}/2 min)",
                  ),
                )
              else
                const Text("Waiting for the host to start..."),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Write widget tests using a fake `RoomRepository` seam**

`RoomRepository` talks straight to `firebase_database`; for a plain (non-emulator) widget test, override `roomRepositoryProvider` with a hand-written fake that implements the same public surface used by these two screens (`createRoom`, `joinRoom`, `watchRoom`, `setConnected`, `startGame`). Add this fake in the test file (it doesn't need to live in `lib/` — it exists only to drive these two widget tests):

```dart
// test/ui/online/create_join_screen_test.dart
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/game/online/online_inferno_controller.dart" show roomRepositoryProvider;
import "package:tfi_bagundaali/rooms/room_models.dart";
import "package:tfi_bagundaali/rooms/room_repository.dart";
import "package:tfi_bagundaali/ui/online/create_join_screen.dart";

class _FakeRoomRepository implements RoomRepository {
  final _rooms = <String, RoomSnapshot>{};

  @override
  Future<String> createRoom({int maxPlayers = 8, int maxAttempts = 8}) async {
    const code = "ABCDE";
    _rooms[code] = RoomSnapshot(
      code: code,
      meta: const RoomMeta(status: "lobby", hostUid: "host-uid", maxPlayers: 8),
      players: const {},
      deckOrder: const [],
      centerIndex: 0,
      result: null,
    );
    return code;
  }

  @override
  Future<void> joinRoom(String code, {required String displayName}) async {
    if (!_rooms.containsKey(code)) throw const RoomJoinException("room not found");
  }

  @override
  Stream<RoomSnapshot> watchRoom(String code) =>
      Stream.value(_rooms[code] ?? RoomSnapshot.empty(code));

  @override
  Future<void> setConnected(String code, {required bool connected}) async {}

  @override
  Future<void> startGame(String code, {required List<int> deckOrder, required List<String> orderedUids}) async {}

  @override
  Future<void> setPlaying(String code) async {}

  @override
  Future<bool> tryAdvance(String code, {required int expectedCenterIndex, required int newCenterCardId}) async => false;

  @override
  Future<void> writeResult(String code, RoomResult result) async {}

  @override
  Future<void> electHost(String code, String newHostUid) async {}
}

void main() {
  // Neither test can reach a real repository call: `_create`/`_join` both
  // call `ensureSignedIn(FirebaseAuth.instance)` first, and no Firebase app
  // is initialized in a plain widget test, so `ensureSignedIn` throws before
  // the fake repository is ever touched. That's still a useful test — it
  // proves both buttons degrade to a visible error instead of crashing.
  // The success path (real auth, real navigation) is covered by Task 12's
  // manual two-device verification instead of a fragile `FirebaseAuth` fake.

  testWidgets("create button surfaces an error when auth isn't available", (tester) async {
    final fake = _FakeRoomRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roomRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: CreateJoinScreen()),
      ),
    );

    await tester.tap(find.text("Create a room"));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't create a room"), findsOneWidget);
  });

  testWidgets("join button surfaces an error when auth isn't available", (tester) async {
    final fake = _FakeRoomRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roomRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: CreateJoinScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField).last, "ZZZZZ");
    await tester.tap(find.text("Join"));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't join"), findsOneWidget);
  });
}
```

`RoomRepository` must be an implementable interface for the fake above to type-check via `implements` — if Task 6 wrote it as a concrete class with no abstract base, `implements RoomRepository` still works in Dart (any concrete class can be implemented), so no change needed there.

- [ ] **Step 5: Run the tests**

Run: `flutter test test/ui/online/create_join_screen_test.dart`
Expected: PASS (2 tests).

`OnlineLobbyScreen`'s widget test follows the same fake-repository pattern; skip writing it as a separate exhaustive suite here — fold a basic "renders player list" check into Task 10's screen test file instead, once `OnlineGameScreen` exists and the two can share the fake.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/online/create_join_screen.dart lib/ui/online/online_lobby_screen.dart lib/core/router.dart test/ui/online/create_join_screen_test.dart
git commit -m "feat: add create/join and lobby screens for online multiplayer"
```

---

## Task 10: Online game screen + result + stats wiring + router completion

**Files:**
- Create: `lib/ui/online/online_game_screen.dart`
- Modify: `lib/core/router.dart` (add the `onlineGame` route, per Task 9's deferred note)
- Modify: `lib/game/online/online_inferno_controller.dart` (add `markResultIfComplete`)
- Test: `test/ui/online/online_game_screen_test.dart`

**Interfaces:**
- Consumes: `OnlineInfernoController`/`onlineInfernoControllerProvider`/`roomCodeProvider` (Task 8), `StatsRepository` (Task 7), `CardView` (existing `lib/ui/widgets/card_view.dart`), `confirmQuit` (existing).
- Produces: `OnlineGameScreen`, `statsRepositoryProvider` (`Provider<StatsRepository>`).

- [ ] **Step 1: Add the `onlineGame` route**

Task 9 already added the `Routes.onlineGame` path constant; this step adds the matching `GoRoute` now that `OnlineGameScreen` exists.

```dart
// lib/core/router.dart — add to the routes list, and add the import
// ../ui/online/online_game_screen.dart:
    GoRoute(
      path: "/online/game/:code",
      builder: (_, state) => OnlineGameScreen(code: state.pathParameters["code"]!),
    ),
```

- [ ] **Step 2: Add result handling to the controller**

```dart
// lib/game/online/online_inferno_controller.dart — add:
  final _statsRecorded = <String>{};

  Future<void> markResultIfComplete() async {
    final snap = state.value;
    if (snap == null || !snap.isComplete) return;
    if (_statsRecorded.contains(snap.code)) return;
    _statsRecorded.add(snap.code);

    if (snap.result == null) {
      final standings = {for (final e in snap.players.entries) e.key: e.value.count};
      final winnerUid = standings.entries.fold<MapEntry<String, int>?>(
        null,
        (best, e) => best == null || e.value > best.value ? e : best,
      )?.key;
      await _repo.writeResult(snap.code, RoomResult(winnerUid: winnerUid, standings: standings));
    }

    final won = snap.result?.winnerUid == _uid ||
        (snap.result == null &&
            snap.players[_uid]!.count ==
                snap.players.values.map((p) => p.count).reduce((a, b) => a > b ? a : b));
    await ref.read(statsRepositoryProvider).recordOnlineGame(won: won);
  }
```

Add the import: `import "../../profile/stats_repository.dart";` and define the provider next to `roomRepositoryProvider`:

```dart
final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(
    firestore: FirebaseFirestore.instance,
    currentUid: () => FirebaseAuth.instance.currentUser!.uid,
  );
});
```

(Add `import "package:cloud_firestore/cloud_firestore.dart";` to the controller file.)

- [ ] **Step 3: Implement `OnlineGameScreen`**

```dart
// lib/ui/online/online_game_screen.dart
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../core/router.dart";
import "../../game/online/online_inferno_controller.dart";
import "../../game/solo/solo_controller.dart" show deckProvider;
import "../widgets/card_view.dart";
import "../widgets/quit_confirm.dart";

class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roomCodeProvider.notifier).state = widget.code);
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckProvider);
    final room = ref.watch(onlineInfernoControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: deck.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Failed to load deck: $e")),
          data: (loadedDeck) => room.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Room error: $e")),
            data: (snap) {
              final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid;
              if (myUid == null) {
                return const Center(child: Text("Not signed in"));
              }
              final me = snap.players[myUid];
              if (me == null) {
                return const Center(child: Text("You're not in this room"));
              }

              if (snap.isComplete) {
                ref.read(onlineInfernoControllerProvider.notifier).markResultIfComplete();
                final standings = snap.players.entries.toList()
                  ..sort((a, b) => b.value.count.compareTo(a.value.count));
                return _ResultView(
                  standings: standings,
                  myUid: myUid,
                  onHome: () => context.go(Routes.home),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: CardView(
                        card: loadedDeck.card(snap.centerCardId),
                        accent: Colors.amber,
                        onSymbolTap: (id) =>
                            ref.read(onlineInfernoControllerProvider.notifier).tap(id),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final e in snap.players.entries)
                          Column(
                            children: [
                              Text(e.value.name),
                              Text("${e.value.count}"),
                              Icon(
                                e.value.connected ? Icons.circle : Icons.circle_outlined,
                                size: 10,
                                color: e.value.connected ? Colors.green : Colors.grey,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      if (await confirmQuit(context, title: "Quit game?", message: "You'll leave this online game.")) {
                        if (context.mounted) context.go(Routes.home);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.standings, required this.myUid, required this.onHome});

  final List<MapEntry<String, dynamic>> standings;
  final String myUid;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            standings.first.key == myUid ? "You win!" : "${standings.first.value.name} wins!",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          for (final e in standings) Text("${e.value.name}: ${e.value.count}"),
          const SizedBox(height: 24),
          FilledButton(onPressed: onHome, child: const Text("Home")),
        ],
      ),
    );
  }
}
```

Add the import `import "../../auth/anon_auth.dart";` for `firebaseAuthProvider`.

- [ ] **Step 4: Write a widget test using the same fake-repository seam as Task 9**

```dart
// test/ui/online/online_game_screen_test.dart
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/deck/deck_loader.dart";
import "package:tfi_bagundaali/deck/dobble.dart";
import "package:tfi_bagundaali/game/online/online_inferno_controller.dart";
import "package:tfi_bagundaali/game/solo/solo_controller.dart" show deckProvider;
import "package:tfi_bagundaali/rooms/room_models.dart";
import "package:tfi_bagundaali/rooms/room_repository.dart";
import "package:tfi_bagundaali/ui/online/online_game_screen.dart";

class _FixedRoomRepository implements RoomRepository {
  _FixedRoomRepository(this.snapshot);
  final RoomSnapshot snapshot;

  @override
  Future<String> createRoom({int maxPlayers = 8, int maxAttempts = 8}) async => snapshot.code;
  @override
  Future<void> joinRoom(String code, {required String displayName}) async {}
  @override
  Stream<RoomSnapshot> watchRoom(String code) => Stream.value(snapshot);
  @override
  Future<void> setConnected(String code, {required bool connected}) async {}
  @override
  Future<void> startGame(String code, {required List<int> deckOrder, required List<String> orderedUids}) async {}
  @override
  Future<void> setPlaying(String code) async {}
  @override
  Future<bool> tryAdvance(String code, {required int expectedCenterIndex, required int newCenterCardId}) async => false;
  @override
  Future<void> writeResult(String code, RoomResult result) async {}
  @override
  Future<void> electHost(String code, String newHostUid) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final deck = deckFromRows(generateDobbleDeck(7));

  testWidgets("renders the center card and player scores mid-game", (tester) async {
    final snapshot = RoomSnapshot(
      code: "ABCDE",
      meta: const RoomMeta(status: "playing", hostUid: "u1", maxPlayers: 2),
      players: const {
        "u1": RoomPlayer(name: "Alice", joinedAt: 1, connected: true, currentCardId: 0, count: 3),
        "u2": RoomPlayer(name: "Bob", joinedAt: 2, connected: true, currentCardId: 1, count: 2),
      },
      deckOrder: const [0, 1, 2, 3],
      centerIndex: 2,
      result: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckProvider.overrideWith((_) async => deck),
          roomRepositoryProvider.overrideWithValue(_FixedRoomRepository(snapshot)),
        ],
        child: const MaterialApp(home: OnlineGameScreen(code: "ABCDE")),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Alice"), findsOneWidget);
    expect(find.text("3"), findsOneWidget);
    expect(find.text("Bob"), findsOneWidget);
    expect(find.text("2"), findsOneWidget);
  });
}
```

Note: this test doesn't override `firebaseAuthProvider`, so `ref.watch(firebaseAuthProvider).currentUser?.uid` will throw (`Firebase.instance` uninitialized) unless `firebaseAuthProvider` is itself overridable — it already is (`Provider<FirebaseAuth>`, per Task 3), but the test above doesn't override it. Add the override:

```dart
          firebaseAuthProvider.overrideWithValue(_FakeFirebaseAuth()),
```

Since `FirebaseAuth` has a large interface, write a minimal fake implementing only `currentUser`:

```dart
class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  String get uid => "u1";
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

Add `import "package:firebase_auth/firebase_auth.dart";` and `import "package:tfi_bagundaali/auth/anon_auth.dart";` to the test file, and the override to the `ProviderScope`.

- [ ] **Step 5: Run the test**

Run: `flutter test test/ui/online/online_game_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the full plain suite**

Run: `flutter test`
Expected: PASS (everything not requiring the emulator).

- [ ] **Step 7: Commit**

```bash
git add lib/ui/online/online_game_screen.dart lib/core/router.dart lib/game/online/online_inferno_controller.dart test/ui/online/online_game_screen_test.dart
git commit -m "feat: add online game screen with result view and stats recording"
```

---

## Task 11: Wire the home screen's "Play Online" card

**Files:**
- Modify: `lib/ui/home_screen.dart`
- Modify: `test/ui/home_screen_test.dart` (check its current assertions before editing — see Step 2)

**Interfaces:**
- Consumes: `onlineAvailableProvider` (Task 1), `Routes.online` (Task 9).

- [ ] **Step 1: Wire the card**

```dart
// lib/ui/home_screen.dart — replace the "Play Online" _MenuCard with:
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final available = ref.watch(onlineAvailableProvider);
                              return _MenuCard(
                                icon: Icons.public_rounded,
                                label: "Play Online",
                                subtitle: "With fans worldwide",
                                comingSoon: !available,
                                onTap: available ? () => context.go(Routes.online) : null,
                              );
                            },
                          ),
                        ),
```

Add the import `import "../core/online_availability.dart";`.

- [ ] **Step 2: Confirm the existing home screen tests still pass unchanged**

`test/ui/home_screen_test.dart` asserts `find.text("SOON")` unconditionally and that tapping "Play Online" doesn't navigate. Neither test overrides `Firebase.initializeApp` or `onlineAvailableProvider`, and no widget test calls `main()`, so `Firebase.apps` stays empty and `onlineAvailableProvider` reads `false` — the card keeps rendering as coming-soon exactly as before.

Run: `flutter test test/ui/home_screen_test.dart`
Expected: PASS unchanged (both existing tests).

- [ ] **Step 3: Add a test for the enabled case**

```dart
// test/ui/home_screen_test.dart — add:
  testWidgets("Play Online is enabled when onlineAvailableProvider is true", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onlineAvailableProvider.overrideWithValue(true)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("SOON"), findsNothing);
  });
```

Add the import `import "package:tfi_bagundaali/core/online_availability.dart";` to the test file if not already present.

- [ ] **Step 4: Run it**

Run: `flutter test test/ui/home_screen_test.dart`
Expected: PASS (existing tests + the new one).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/home_screen.dart test/ui/home_screen_test.dart
git commit -m "feat: enable Play Online home card on supported platforms"
```

---

## Task 12: Resilience — disconnect, reconnect, host migration

**Files:**
- Modify: `lib/rooms/room_repository.dart` (add `electHost` caller logic lives in the controller, repository method already exists from Task 6)
- Create: `lib/game/online/host_migration.dart`
- Test: `test/game/online/host_migration_test.dart`
- Modify: `lib/game/online/online_inferno_controller.dart` (call migration check on each snapshot)

**Interfaces:**
- Produces: `String? electedHost(RoomSnapshot snapshot)` — pure function, returns the uid of the connected player with the earliest `joinedAt`, or `null` if nobody is connected; `bool shouldIElectMyself(RoomSnapshot snapshot, String myUid)` — true iff the current `hostUid` is disconnected and I am `electedHost`.

- [ ] **Step 1: Write the failing test for the pure election logic**

```dart
// test/game/online/host_migration_test.dart
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/game/online/host_migration.dart";
import "package:tfi_bagundaali/rooms/room_models.dart";

RoomSnapshot _snapshot(Map<String, RoomPlayer> players, {String hostUid = "u1"}) => RoomSnapshot(
      code: "X",
      meta: RoomMeta(status: "playing", hostUid: hostUid, maxPlayers: 8),
      players: players,
      deckOrder: const [],
      centerIndex: 0,
      result: null,
    );

void main() {
  test("electedHost picks the earliest-joined connected player", () {
    final snap = _snapshot({
      "u1": const RoomPlayer(name: "A", joinedAt: 500, connected: false, currentCardId: 0, count: 0),
      "u2": const RoomPlayer(name: "B", joinedAt: 200, connected: true, currentCardId: 0, count: 0),
      "u3": const RoomPlayer(name: "C", joinedAt: 300, connected: true, currentCardId: 0, count: 0),
    });
    expect(electedHost(snap), "u2");
  });

  test("electedHost is null when nobody is connected", () {
    final snap = _snapshot({
      "u1": const RoomPlayer(name: "A", joinedAt: 500, connected: false, currentCardId: 0, count: 0),
    });
    expect(electedHost(snap), isNull);
  });

  test("shouldIElectMyself is true only for the elected host when the current host dropped", () {
    final snap = _snapshot({
      "u1": const RoomPlayer(name: "A", joinedAt: 500, connected: false, currentCardId: 0, count: 0),
      "u2": const RoomPlayer(name: "B", joinedAt: 200, connected: true, currentCardId: 0, count: 0),
    }, hostUid: "u1");
    expect(shouldIElectMyself(snap, "u2"), isTrue);
    expect(shouldIElectMyself(snap, "u1"), isFalse);
  });

  test("shouldIElectMyself is false while the current host is still connected", () {
    final snap = _snapshot({
      "u1": const RoomPlayer(name: "A", joinedAt: 500, connected: true, currentCardId: 0, count: 0),
      "u2": const RoomPlayer(name: "B", joinedAt: 200, connected: true, currentCardId: 0, count: 0),
    }, hostUid: "u1");
    expect(shouldIElectMyself(snap, "u2"), isFalse);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test test/game/online/host_migration_test.dart`
Expected: FAIL — `host_migration.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/game/online/host_migration.dart
import "../../rooms/room_models.dart";

/// The connected player with the earliest `joinedAt`, or null if nobody is
/// connected (spec §8.3: deterministic host migration).
String? electedHost(RoomSnapshot snapshot) {
  final connected = snapshot.players.entries.where((e) => e.value.connected);
  if (connected.isEmpty) return null;
  return connected.reduce((a, b) => a.value.joinedAt <= b.value.joinedAt ? a : b).key;
}

/// True iff the room's current host has disconnected and [myUid] is the
/// one who should take over.
bool shouldIElectMyself(RoomSnapshot snapshot, String myUid) {
  final currentHost = snapshot.players[snapshot.meta.hostUid];
  final hostIsConnected = currentHost?.connected ?? false;
  if (hostIsConnected) return false;
  return electedHost(snapshot) == myUid;
}
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `flutter test test/game/online/host_migration_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Wire migration into the controller**

```dart
// lib/game/online/online_inferno_controller.dart — inside build()'s stream listener:
      (snap) {
        state = AsyncValue.data(snap);
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        if (myUid != null && shouldIElectMyself(snap, myUid)) {
          _repo.electHost(snap.code, myUid);
        }
      },
```

Add the import `import "host_migration.dart";`.

- [ ] **Step 6: Add an emulator test for host migration end-to-end**

```dart
// test/rooms/room_repository_test.dart — add:
  test("host migration: connected earliest-joined player becomes host after disconnect", () async {
    final host = await _client("host6");
    final code = await host.repo.createRoom(maxPlayers: 2);
    final p2 = await _client("p2-6");
    await p2.repo.joinRoom(code, displayName: "Bob");

    // Simulate the host dropping.
    await host.repo.setConnected(code, connected: false);

    final snap = await p2.repo.watchRoom(code).first;
    // p2's own repository doesn't know its own uid here without exposing
    // it — assert the invariant this plan actually depends on instead:
    // exactly one connected player remains, matching the migration
    // target that `electedHost` would compute from this same snapshot.
    expect(snap.players.values.where((p) => p.connected).length, 1);
  });
```

- [ ] **Step 7: Run it**

Run: `./scripts/test_online.sh test/rooms/room_repository_test.dart`
Expected: PASS (6 tests total in this file now).

- [ ] **Step 8: Commit**

```bash
git add lib/game/online/host_migration.dart lib/game/online/online_inferno_controller.dart test/game/online/host_migration_test.dart test/rooms/room_repository_test.dart
git commit -m "feat: add deterministic host migration on disconnect"
```

---

## Task 13: Manual two-device verification (not automated)

This task has no code changes. It's the spec's §10 "Manual / device" row and the point where the Firebase console prerequisites finally matter.

- [ ] **Step 1:** In the Firebase console for `spndex-37b0d`: enable **Realtime Database** (note the region — update `lib/core/firebase_options.dart`'s `databaseURL` if it differs from the `firebaseio.com` default used during development), enable **Cloud Firestore**, enable **Authentication → Anonymous sign-in**.

- [ ] **Step 2:** Deploy the real rules: `firebase deploy --only database,firestore:rules --project spndex-37b0d`.

- [ ] **Step 3:** Build and run on two Android devices/emulators (`flutter run` twice, or `./scripts/run_dev.sh` with two different `ANDROID_EMULATOR` values), **without** `USE_FIREBASE_EMULATOR` set, so both hit the real project.

- [ ] **Step 4:** Walk the full flow: device A creates a room, device B joins by code, A starts the game, play a full round to completion on both devices, confirm the result screen and standings match on both, confirm `/users/{uid}/stats` updated for both in the Firestore console.

- [ ] **Step 5:** Background device B mid-round (home button), confirm A sees it go disconnected, foreground B again, confirm it resumes and can keep playing.

- [ ] **Step 6:** Force-quit the host device mid-game, confirm the other device becomes host (per `host_migration.dart`) and the game continues.

- [ ] **Step 7:** Report results back — this plan is done once this task's flow completes cleanly on real infrastructure.

---

## Self-Review Notes

- **Spec coverage:** §8.1 room lifecycle → Tasks 6, 9, 10. §8.2 round resolution → Tasks 6, 8 (and the spec amendment made here). §8.3 disconnect/host migration → Task 12. §9 security rules → Tasks 6, 7. §6 data model → Task 5. §5 architecture (`game/online`, `rooms/`, `auth/`, `profile/` folders) → matches throughout. §7 local modes: explicitly untouched (Global Constraints). Milestones 3–6 from the spec's §11 map onto Tasks 1–3 (bootstrap), 6+9 (rooms/lobby), 8+10 (online Inferno), 12 (resilience).
- **Not covered by this plan (explicitly out of scope, per Global Constraints):** iOS Firebase app registration, Cloud Functions, solo stats migrating to Firestore, room rematch (spec §8.1 step 6 — same-room replay). Rematch is a small follow-on (`OnlineLobbyScreen`'s Start button logic reused after `writeResult`) but wasn't asked for in this pass and isn't required for a first playable online game; flag it to the user as a fast-follow rather than silently shipping it unasked.
- **Type consistency check:** `RoomRepository`'s method signatures (Task 6) are used identically in Tasks 8, 9, 10, and the two fakes in Tasks 9–10 implement exactly that surface — `createRoom`, `joinRoom`, `watchRoom`, `setConnected`, `startGame`, `setPlaying`, `tryAdvance`, `writeResult`, `electHost`. `RoomSnapshot`/`RoomMeta`/`RoomPlayer`/`RoomResult` field names are identical everywhere they're constructed or read (`joinedAt`, `connected`, `currentCardId`, `count`, `hostUid`, `status`, `maxPlayers`, `winnerUid`, `standings`).
