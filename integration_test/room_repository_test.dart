import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:tfi_bagundaali/rooms/room_models.dart";
import "package:tfi_bagundaali/rooms/room_repository.dart";

/// Signs in a fresh anonymous user against the emulator and returns a
/// [RoomRepository] bound to that user's uid — used to simulate one
/// "client" in multi-client scenarios.
Future<({RoomRepository repo, String uid})> client(String appName) async {
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      "createRoom returns a joinable code; join then reject a third + wrong status",
      (tester) async {
    final host = await client("host1");
    final code = await host.repo.createRoom(maxPlayers: 2);
    await host.repo.joinRoom(code, displayName: "Host");

    final p2 = await client("p2-1");
    await p2.repo.joinRoom(code, displayName: "Bob");

    final p3 = await client("p3-1");
    await expectLater(
      p3.repo.joinRoom(code, displayName: "Carol"),
      throwsA(isA<RoomJoinException>()),
    );
  });

  testWidgets("joinRoom rejects once the room has left lobby status",
      (tester) async {
    final host = await client("host2");
    final code = await host.repo.createRoom(maxPlayers: 8);
    await host.repo.joinRoom(code, displayName: "Host");
    final p2 = await client("p2-2");
    await p2.repo.joinRoom(code, displayName: "Bob");
    await host.repo.startGame(
      code,
      deckOrder: [0, 1, 2],
      orderedUids: [host.uid, p2.uid],
    );
    final p3 = await client("p3-2");
    await expectLater(
      p3.repo.joinRoom(code, displayName: "Carol"),
      throwsA(isA<RoomJoinException>()),
    );
  });

  testWidgets("watchRoom streams player joins", (tester) async {
    final host = await client("host3");
    final code = await host.repo.createRoom(maxPlayers: 8);
    await host.repo.joinRoom(code, displayName: "Host");
    final events = <int>[];
    final sub =
        host.repo.watchRoom(code).listen((s) => events.add(s.players.length));

    final p2 = await client("p2-3");
    await p2.repo.joinRoom(code, displayName: "Bob");

    await Future<void>.delayed(const Duration(milliseconds: 500));
    await sub.cancel();
    expect(events.last, 2);
  });

  testWidgets(
      "tryAdvance: two clients racing the same centerIndex — exactly one wins",
      (tester) async {
    final host = await client("host4");
    final code = await host.repo.createRoom(maxPlayers: 2);
    await host.repo.joinRoom(code, displayName: "Host");
    final p2 = await client("p2-4");
    await p2.repo.joinRoom(code, displayName: "Bob");
    await host.repo.startGame(
      code,
      deckOrder: List.generate(57, (i) => i),
      orderedUids: [host.uid, p2.uid],
    );

    final results = await Future.wait([
      host.repo.tryAdvance(code, expectedCenterIndex: 2, newCenterCardId: 5),
      p2.repo.tryAdvance(code, expectedCenterIndex: 2, newCenterCardId: 5),
    ]);
    expect(results.where((r) => r).length, 1);
  });

  testWidgets("writeResult is write-once", (tester) async {
    final host = await client("host5");
    final code = await host.repo.createRoom(maxPlayers: 2);
    await host.repo.joinRoom(code, displayName: "Host");
    await host.repo.writeResult(
      code,
      const RoomResult(winnerUid: "u1", standings: {"u1": 30}),
    );
    await host.repo.writeResult(
      code,
      const RoomResult(winnerUid: "u2", standings: {"u2": 1}),
    );
    final snap = await host.repo.watchRoom(code).first;
    expect(snap.result!.winnerUid, "u1");
  });

  testWidgets(
      "host migration: connected earliest-joined player becomes host after disconnect",
      (tester) async {
    final host = await client("host6");
    final code = await host.repo.createRoom(maxPlayers: 2);
    await host.repo.joinRoom(code, displayName: "Host");
    final p2 = await client("p2-6");
    await p2.repo.joinRoom(code, displayName: "Bob");

    await host.repo.setConnected(code, connected: false);

    final snap = await p2.repo.watchRoom(code).first;
    expect(snap.players.values.where((p) => p.connected).length, 1);
  });
}
