import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:tfi_bagundali/deck/deck_loader.dart";
import "package:tfi_bagundali/deck/dobble.dart";
import "package:tfi_bagundali/deck/match_rules.dart";
import "package:tfi_bagundali/game/online/online_inferno_controller.dart";
import "package:tfi_bagundali/game/solo/solo_controller.dart"
    show deckProvider;
import "package:tfi_bagundali/rooms/room_repository.dart";

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
    repo:
        RoomRepository(root: db.ref(), currentUid: () => credential.user!.uid),
    uid: credential.user!.uid,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final deck = deckFromRows(generateDobbleDeck(7));

  testWidgets("two players play a full room to completion; counts sum to 55",
      (tester) async {
    final host = await client("oic-host");
    final p2 = await client("oic-p2");

    final code = await host.repo.createRoom(maxPlayers: 2);
    await host.repo.joinRoom(code, displayName: "Host");
    await p2.repo.joinRoom(code, displayName: "Bob");
    await host.repo.startGame(
      code,
      deckOrder: List.generate(57, (i) => i),
      orderedUids: [host.uid, p2.uid],
    );
    await host.repo.setPlaying(code);

    final hostContainer = ProviderContainer(
      overrides: [
        deckProvider.overrideWith((_) async => deck),
        roomCodeProvider.overrideWith((_) => code),
        roomRepositoryProvider.overrideWithValue(host.repo),
        currentUidProvider.overrideWithValue(() => host.uid),
      ],
    );
    final p2Container = ProviderContainer(
      overrides: [
        deckProvider.overrideWith((_) async => deck),
        roomCodeProvider.overrideWith((_) => code),
        roomRepositoryProvider.overrideWithValue(p2.repo),
        currentUidProvider.overrideWithValue(() => p2.uid),
      ],
    );
    await hostContainer.read(deckProvider.future);
    await p2Container.read(deckProvider.future);
    // Prime each controller's stream subscription.
    hostContainer.read(onlineInfernoControllerProvider);
    p2Container.read(onlineInfernoControllerProvider);

    Future<void> driveOneCorrectTap(ProviderContainer c, String uid) async {
      final snap = await c.read(roomRepositoryProvider).watchRoom(code).first;
      if (snap.isComplete) return;
      final held = deck.card(snap.players[uid]!.currentCardId);
      final center = deck.card(snap.centerCardId);
      final symbol = sharedSymbol(held, center);
      c.read(onlineInfernoControllerProvider.notifier).tap(symbol);
      await Future<void>.delayed(const Duration(milliseconds: 200));
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

  testWidgets("a wrong tap does not advance the room", (tester) async {
    final host = await client("oic-host2");
    final code = await host.repo.createRoom(maxPlayers: 2);
    await host.repo.joinRoom(code, displayName: "Host");
    await host.repo.startGame(
      code,
      deckOrder: List.generate(57, (i) => i),
      orderedUids: [host.uid],
    );
    await host.repo.setPlaying(code);

    final container = ProviderContainer(
      overrides: [
        deckProvider.overrideWith((_) async => deck),
        roomCodeProvider.overrideWith((_) => code),
        roomRepositoryProvider.overrideWithValue(host.repo),
        currentUidProvider.overrideWithValue(() => host.uid),
      ],
    );
    await container.read(deckProvider.future);
    container.read(onlineInfernoControllerProvider);

    final before = await host.repo.watchRoom(code).first;
    final held = deck.card(before.players[host.uid]!.currentCardId);
    final center = deck.card(before.centerCardId);
    final correct = sharedSymbol(held, center);
    final wrong = held.symbolIds.firstWhere((s) => s != correct);

    container.read(onlineInfernoControllerProvider.notifier).tap(wrong);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final after = await host.repo.watchRoom(code).first;
    expect(after.centerIndex, before.centerIndex);

    container.dispose();
  });
}
