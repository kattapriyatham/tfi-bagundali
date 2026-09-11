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

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  ensureSignedIn(auth);
  return auth.authStateChanges();
});
