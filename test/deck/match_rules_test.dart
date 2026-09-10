import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/deck/deck_loader.dart";
import "package:tfi_bagundaali/deck/dobble.dart";
import "package:tfi_bagundaali/deck/match_rules.dart";

void main() {
  final deck = deckFromRows(generateDobbleDeck(7));

  test("sharedSymbol returns the one common id for every pair", () {
    for (var i = 0; i < deck.cards.length; i++) {
      for (var j = i + 1; j < deck.cards.length; j++) {
        final s = sharedSymbol(deck.cards[i], deck.cards[j]);
        expect(deck.cards[i].symbolIds, contains(s));
        expect(deck.cards[j].symbolIds, contains(s));
      }
    }
  });

  test("isMatch is true only for the shared symbol", () {
    final a = deck.card(0);
    final b = deck.card(1);
    final s = sharedSymbol(a, b);
    expect(isMatch(a, b, s), isTrue);
    for (final other in a.symbolIds.where((x) => x != s)) {
      expect(isMatch(a, b, other), isFalse);
    }
  });
}
