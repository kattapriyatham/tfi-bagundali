import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";

import "../storage/best_time_store.dart";
import "anon_auth.dart";

/// Permanently deletes the signed-in user's data: their Firestore stats
/// document, locally stored best time, and the Firebase Auth account itself.
/// A fresh anonymous session is started afterward so the app keeps working.
Future<void> deleteAccountAndData({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
  required BestTimeStore bestTimeStore,
}) async {
  final user = auth.currentUser;
  if (user == null) return;
  await firestore.collection("users").doc(user.uid).delete();
  await bestTimeStore.clear();
  await user.delete();
  await ensureSignedIn(auth);
}
