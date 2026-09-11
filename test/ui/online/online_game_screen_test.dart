import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/auth/anon_auth.dart";
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
  Future<String> createRoom({int maxPlayers = 8, int maxAttempts = 8}) async =>
      snapshot.code;
  @override
  Future<void> joinRoom(String code, {required String displayName}) async {}
  @override
  Stream<RoomSnapshot> watchRoom(String code) => Stream.value(snapshot);
  @override
  Future<void> setConnected(String code, {required bool connected}) async {}
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

class _FakeUser implements User {
  @override
  String get uid => "u1";
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final deck = deckFromRows(generateDobbleDeck(7));

  testWidgets("renders the center card and player scores mid-game",
      (tester) async {
    const snapshot = RoomSnapshot(
      code: "ABCDE",
      meta: RoomMeta(status: "playing", hostUid: "u1", maxPlayers: 2),
      players: {
        "u1": RoomPlayer(
          name: "Alice",
          joinedAt: 1,
          connected: true,
          currentCardId: 0,
          count: 3,
        ),
        "u2": RoomPlayer(
          name: "Bob",
          joinedAt: 2,
          connected: true,
          currentCardId: 1,
          count: 2,
        ),
      },
      deckOrder: [0, 1, 2, 3],
      centerIndex: 2,
      result: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckProvider.overrideWith((_) async => deck),
          roomRepositoryProvider.overrideWithValue(
            _FixedRoomRepository(snapshot),
          ),
          roomCodeProvider.overrideWith((_) => "ABCDE"),
          firebaseAuthProvider.overrideWithValue(_FakeFirebaseAuth()),
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
