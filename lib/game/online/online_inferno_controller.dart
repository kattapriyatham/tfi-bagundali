import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../deck/deck.dart";
import "../../deck/match_rules.dart";
import "../../profile/stats_repository.dart";
import "../../rooms/room_models.dart";
import "../../rooms/room_repository.dart";
import "../solo/solo_controller.dart" show deckProvider;
import "host_migration.dart";

/// The room code the controller operates on. Set by the lobby screen
/// before navigating to the game screen.
final roomCodeProvider = StateProvider<String?>((ref) => null);

final currentUidProvider = Provider<String Function()>(
  (ref) => () => FirebaseAuth.instance.currentUser!.uid,
);

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(
    root: FirebaseDatabase.instance.ref(),
    currentUid: ref.watch(currentUidProvider),
  );
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(
    firestore: FirebaseFirestore.instance,
    currentUid: ref.watch(currentUidProvider),
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
          (snap) {
            state = AsyncValue.data(snap);
            final myUid = ref.read(currentUidProvider)();
            if (shouldIElectMyself(snap, myUid)) {
              repo.electHost(snap.code, myUid);
            }
          },
          onError: (Object e, StackTrace st) => state = AsyncValue.error(e, st),
        );
    ref.onDispose(sub.cancel);
    return const AsyncValue.loading();
  }

  Deck get _deck => ref.read(deckProvider).requireValue;
  RoomRepository get _repo => ref.read(roomRepositoryProvider);
  String get _uid => ref.read(currentUidProvider)();

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

  final _statsRecorded = <String>{};

  /// Writes the room result (once, if nobody has yet) and this client's own
  /// Firestore stats. Safe to call repeatedly — no-ops after the first call
  /// per room code.
  Future<void> markResultIfComplete() async {
    final snap = state.value;
    if (snap == null || !snap.isComplete) return;
    if (_statsRecorded.contains(snap.code)) return;
    _statsRecorded.add(snap.code);

    var result = snap.result;
    if (result == null) {
      final standings = {
        for (final e in snap.players.entries) e.key: e.value.count,
      };
      final winnerUid = standings.entries
          .fold<MapEntry<String, int>?>(
            null,
            (best, e) => best == null || e.value > best.value ? e : best,
          )
          ?.key;
      result = RoomResult(winnerUid: winnerUid, standings: standings);
      await _repo.writeResult(snap.code, result);
    }

    final myCount = snap.players[_uid]?.count ?? 0;
    final maxCount = snap.players.values
        .map((p) => p.count)
        .fold(0, (a, b) => a > b ? a : b);
    final won = result.winnerUid == _uid || myCount == maxCount;
    await ref.read(statsRepositoryProvider).recordOnlineGame(won: won);
  }
}

final onlineInfernoControllerProvider =
    NotifierProvider<OnlineInfernoController, AsyncValue<RoomSnapshot>>(
  OnlineInfernoController.new,
);
