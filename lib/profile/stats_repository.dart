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
    await ref.set(
      {
        "stats": {
          "gamesPlayed": FieldValue.increment(1),
          "onlinePlayed": FieldValue.increment(1),
          if (won) "gamesWon": FieldValue.increment(1),
          "lastPlayedAt": FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }
}
