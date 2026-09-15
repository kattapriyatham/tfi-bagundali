import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/game/online/online_inferno_controller.dart"
    show roomRepositoryProvider;
import "package:tfi_bagundali/rooms/room_models.dart";
import "package:tfi_bagundali/rooms/room_repository.dart";
import "package:tfi_bagundali/ui/online/create_join_screen.dart";

class _FakeRoomRepository implements RoomRepository {
  final rooms = <String, RoomSnapshot>{};

  @override
  Future<String> createRoom({int maxPlayers = 8, int maxAttempts = 8}) async {
    const code = "ABCDE";
    rooms[code] = const RoomSnapshot(
      code: code,
      meta: RoomMeta(status: "lobby", hostUid: "host-uid", maxPlayers: 8),
      players: {},
      deckOrder: [],
      centerIndex: 0,
      result: null,
    );
    return code;
  }

  @override
  Future<void> joinRoom(String code, {required String displayName}) async {
    if (!rooms.containsKey(code)) {
      throw const RoomJoinException("room not found");
    }
  }

  @override
  Stream<RoomSnapshot> watchRoom(String code) =>
      Stream.value(rooms[code] ?? RoomSnapshot.empty(code));

  @override
  Future<void> setConnected(String code, {required bool connected}) async {}

  @override
  Future<void> reconnect(String code) async {}

  @override
  Future<RoomSnapshot> getRoom(String code) async =>
      rooms[code] ?? RoomSnapshot.empty(code);

  @override
  Future<void> startGame(
    String code, {
    required List<int> deckOrder,
    required List<String> orderedUids,
  }) async {}

  @override
  Future<void> setPlaying(String code) async {}

  @override
  Future<bool> tryAdvance(
    String code, {
    required int expectedCenterIndex,
    required int newCenterCardId,
  }) async =>
      false;

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
  // The success path (real auth, real navigation) is covered by manual
  // two-device verification instead of a fragile `FirebaseAuth` fake.

  testWidgets("create button surfaces an error when auth isn't available",
      (tester) async {
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

  testWidgets("join button surfaces an error when auth isn't available",
      (tester) async {
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
