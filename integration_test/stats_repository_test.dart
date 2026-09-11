import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:tfi_bagundaali/profile/stats_repository.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "fake",
        appId: "1:0:android:0",
        messagingSenderId: "0",
        projectId: "spndex-37b0d",
      ),
    );
    await FirebaseAuth.instance.useAuthEmulator("localhost", 9099);
    FirebaseFirestore.instance.useFirestoreEmulator("localhost", 8080);
  });

  testWidgets("recordOnlineGame increments counters across two calls",
      (tester) async {
    await FirebaseAuth.instance.signOut();
    final credential = await FirebaseAuth.instance.signInAnonymously();

    final repo = StatsRepository(
      firestore: FirebaseFirestore.instance,
      currentUid: () => credential.user!.uid,
    );

    await repo.recordOnlineGame(won: true);
    await repo.recordOnlineGame(won: false);

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(credential.user!.uid)
        .get();
    final stats = doc.data()!["stats"] as Map<String, dynamic>;
    expect(stats["gamesPlayed"], 2);
    expect(stats["onlinePlayed"], 2);
    expect(stats["gamesWon"], 1);
  });

  testWidgets("a user cannot write another user's stats", (tester) async {
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();

    final repo = StatsRepository(
      firestore: FirebaseFirestore.instance,
      currentUid: () => "someone-else",
    );
    await expectLater(
      repo.recordOnlineGame(won: true),
      throwsA(isA<FirebaseException>()),
    );
  });
}
