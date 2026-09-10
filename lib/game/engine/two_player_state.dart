import "package:freezed_annotation/freezed_annotation.dart";

import "../../deck/deck.dart";
import "../../deck/match_rules.dart";
import "round_state.dart" show shuffledDeckOrder;

part "two_player_state.freezed.dart";

/// Local hot-seat two-player state for the "tabletop" split-screen mode.
///
/// One shared shuffled deck. Each player holds one card; the rest form a
/// central pile. Both race to match their own held card with the current
/// central card; the first correct tap takes the central card (it becomes
/// that player's new held card) and exposes the next one. The player with
/// the most cards when the pile is empty wins.
@freezed
class TwoPlayerState with _$TwoPlayerState {
  const TwoPlayerState._();

  const factory TwoPlayerState({
    required List<int> deckOrder,
    required int centerIndex,
    required int heldP1,
    required int heldP2,
    required int countP1,
    required int countP2,
  }) = _TwoPlayerState;

  bool get isComplete => centerIndex >= deckOrder.length;

  int get centerCardId => deckOrder[centerIndex];

  int heldFor(int player) => player == 1 ? heldP1 : heldP2;

  /// 1 or 2 for the leader, 0 for a tie. Only meaningful once [isComplete].
  int get winner {
    if (countP1 == countP2) return 0;
    return countP1 > countP2 ? 1 : 2;
  }
}

TwoPlayerState startTwoPlayer(int seed) {
  final order = shuffledDeckOrder(seed);
  return TwoPlayerState(
    deckOrder: order,
    centerIndex: 2,
    heldP1: order[0],
    heldP2: order[1],
    countP1: 0,
    countP2: 0,
  );
}

/// Returns a new state for a correct tap by [player] (1 or 2), or null for
/// a wrong tap.
TwoPlayerState? applyTwoPlayerTap({
  required TwoPlayerState state,
  required int player,
  required int tappedSymbolId,
  required Deck deck,
}) {
  final held = deck.card(state.heldFor(player));
  final center = deck.card(state.centerCardId);
  if (!isMatch(held, center, tappedSymbolId)) return null;

  final took = center.id;
  return state.copyWith(
    centerIndex: state.centerIndex + 1,
    heldP1: player == 1 ? took : state.heldP1,
    heldP2: player == 2 ? took : state.heldP2,
    countP1: player == 1 ? state.countP1 + 1 : state.countP1,
    countP2: player == 2 ? state.countP2 + 1 : state.countP2,
  );
}
