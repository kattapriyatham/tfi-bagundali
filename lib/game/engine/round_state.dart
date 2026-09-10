import "package:freezed_annotation/freezed_annotation.dart";

import "../../core/rng.dart";
import "../../deck/deck.dart";
import "../../deck/match_rules.dart";

part "round_state.freezed.dart";

@freezed
class RoundState with _$RoundState {
  const factory RoundState({
    required List<int> deckOrder,
    required int centerIndex,
    required int heldCardId,
    required int collected,
  }) = _RoundState;
}

List<int> shuffledDeckOrder(int seed) {
  final rng = SeededRng(seed);
  final order = [for (var i = 0; i < 57; i++) i];
  for (var i = order.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = order[i];
    order[i] = order[j];
    order[j] = tmp;
  }
  return order;
}

RoundState startRun(List<int> deckOrder) => RoundState(
      deckOrder: deckOrder,
      centerIndex: 1,
      heldCardId: deckOrder.first,
      collected: 0,
    );

bool isComplete(RoundState s) => s.centerIndex >= s.deckOrder.length;

int centerCardId(RoundState s) {
  assert(!isComplete(s), "run is complete");
  return s.deckOrder[s.centerIndex];
}

RoundState? applyTap({
  required RoundState state,
  required int tappedSymbolId,
  required Deck deck,
}) {
  final held = deck.card(state.heldCardId);
  final center = deck.card(centerCardId(state));
  if (!isMatch(held, center, tappedSymbolId)) return null;
  return state.copyWith(
    centerIndex: state.centerIndex + 1,
    heldCardId: center.id,
    collected: state.collected + 1,
  );
}
