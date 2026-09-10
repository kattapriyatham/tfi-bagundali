import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/deck/deck_loader.dart";
import "package:tfi_bagundaali/deck/dobble.dart";
import "package:tfi_bagundaali/deck/match_rules.dart";
import "package:tfi_bagundaali/game/engine/round_state.dart";

void main() {
  final deck = deckFromRows(generateDobbleDeck(7));

  test("startRun deals one held card and points at the rest", () {
    final s = startRun(shuffledDeckOrder(1));
    expect(s.centerIndex, 1);
    expect(s.collected, 0);
    expect(s.heldCardId, s.deckOrder.first);
    expect(isComplete(s), isFalse);
  });

  test("a correct tap advances and takes the center card", () {
    final s = startRun(shuffledDeckOrder(2));
    final match = sharedSymbol(
      deck.card(s.heldCardId),
      deck.card(centerCardId(s)),
    );
    final taken = centerCardId(s);
    final next = applyTap(state: s, tappedSymbolId: match, deck: deck);
    expect(next, isNotNull);
    expect(next!.collected, 1);
    expect(next.heldCardId, taken);
    expect(next.centerIndex, 2);
  });

  test("a wrong tap returns null", () {
    final s = startRun(shuffledDeckOrder(3));
    final match =
        sharedSymbol(deck.card(s.heldCardId), deck.card(centerCardId(s)));
    final wrong =
        deck.card(s.heldCardId).symbolIds.firstWhere((x) => x != match);
    expect(applyTap(state: s, tappedSymbolId: wrong, deck: deck), isNull);
  });

  test("a full run completes after 56 correct taps", () {
    var s = startRun(shuffledDeckOrder(4));
    var guard = 0;
    while (!isComplete(s) && guard++ < 100) {
      final match = sharedSymbol(
        deck.card(s.heldCardId),
        deck.card(centerCardId(s)),
      );
      s = applyTap(state: s, tappedSymbolId: match, deck: deck)!;
    }
    expect(isComplete(s), isTrue);
    expect(s.collected, 56);
  });

  test("shuffledDeckOrder is a permutation of 0..56, deterministic per seed",
      () {
    final a = shuffledDeckOrder(9);
    final b = shuffledDeckOrder(9);
    expect(a, b);
    expect(a.toSet(), {for (var i = 0; i < 57; i++) i});
  });
}
