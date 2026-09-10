import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../deck/deck.dart";
import "../engine/two_player_state.dart";
import "../solo/solo_controller.dart" show deckProvider;

@immutable
class TwoPlayerView {
  const TwoPlayerView({
    required this.state,
    required this.wrongP1,
    required this.wrongP2,
  });

  final TwoPlayerState state;
  final int? wrongP1;
  final int? wrongP2;

  int wrongFor(int player) => player == 1 ? wrongP1 ?? -1 : wrongP2 ?? -1;

  @override
  bool operator ==(Object other) =>
      other is TwoPlayerView &&
      other.state == state &&
      other.wrongP1 == wrongP1 &&
      other.wrongP2 == wrongP2;

  @override
  int get hashCode => Object.hash(state, wrongP1, wrongP2);
}

class TwoPlayerController extends Notifier<TwoPlayerView> {
  DateTime Function() _clock = DateTime.now;
  DateTime? _lockP1;
  DateTime? _lockP2;

  @override
  TwoPlayerView build() => TwoPlayerView(
        state: startTwoPlayer(0),
        wrongP1: null,
        wrongP2: null,
      );

  Deck get _deck => ref.read(deckProvider).requireValue;

  void start({int? seed, DateTime Function()? clock}) {
    _clock = clock ?? DateTime.now;
    _lockP1 = null;
    _lockP2 = null;
    state = TwoPlayerView(
      state: startTwoPlayer(seed ?? _clock().millisecondsSinceEpoch),
      wrongP1: null,
      wrongP2: null,
    );
  }

  void tap(int player, int symbolId) {
    if (state.state.isComplete) return;
    final now = _clock();
    final lock = player == 1 ? _lockP1 : _lockP2;
    if (lock != null && now.isBefore(lock)) return;

    final next = applyTwoPlayerTap(
      state: state.state,
      player: player,
      tappedSymbolId: symbolId,
      deck: _deck,
    );

    if (next == null) {
      final until = now.add(const Duration(milliseconds: 600));
      if (player == 1) {
        _lockP1 = until;
        state = TwoPlayerView(
          state: state.state,
          wrongP1: symbolId,
          wrongP2: state.wrongP2,
        );
      } else {
        _lockP2 = until;
        state = TwoPlayerView(
          state: state.state,
          wrongP1: state.wrongP1,
          wrongP2: symbolId,
        );
      }
      return;
    }

    // Debounce a resting finger so it does not re-tap the fresh card.
    final debounce = now.add(const Duration(milliseconds: 250));
    if (player == 1) {
      _lockP1 = debounce;
    } else {
      _lockP2 = debounce;
    }
    state = TwoPlayerView(state: next, wrongP1: null, wrongP2: null);
  }
}

final twoPlayerControllerProvider =
    NotifierProvider<TwoPlayerController, TwoPlayerView>(
  TwoPlayerController.new,
);
