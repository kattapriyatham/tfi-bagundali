import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../deck/deck.dart";
import "../../deck/match_rules.dart";
import "../../rooms/room_models.dart";
import "../../rooms/room_repository.dart";
import "../solo/solo_controller.dart" show deckProvider;

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

class OnlineInfernoController extends Notifier<AsyncValue<RoomSnapshot>> {
  @override
  AsyncValue<RoomSnapshot> build() {
    final code = ref.watch(roomCodeProvider);
    if (code == null) {
      return const AsyncValue.error("no room code set", StackTrace.empty);
    }
    final repo = ref.watch(roomRepositoryProvider);
    final sub = repo.watchRoom(code).listen(
          (snap) => state = AsyncValue.data(snap),
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
}

final onlineInfernoControllerProvider =
    NotifierProvider<OnlineInfernoController, AsyncValue<RoomSnapshot>>(
  OnlineInfernoController.new,
);
