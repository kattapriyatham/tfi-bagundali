import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:tfi_bagundali/auth/anon_auth.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("ensureSignedIn signs in anonymously then is idempotent",
      (tester) async {
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
