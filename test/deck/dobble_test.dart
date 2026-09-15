import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/deck/dobble.dart";

void main() {
  final deck = generateDobbleDeck(7);

  test("produces 57 cards of 8 symbols", () {
    expect(deck.length, 57);
    for (final card in deck) {
      expect(card.length, 8);
      expect(card.toSet().length, 8, reason: "no repeats within a card");
    }
  });

  test("uses exactly 57 distinct symbols, each on 8 cards", () {
    final counts = <int, int>{};
    for (final card in deck) {
      for (final s in card) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    expect(counts.length, 57);
    expect(counts.keys.reduce((a, b) => a > b ? a : b), 56);
    expect(counts.values.every((c) => c == 8), isTrue);
  });

  test("every pair of cards shares exactly one symbol", () {
    for (var i = 0; i < deck.length; i++) {
      for (var j = i + 1; j < deck.length; j++) {
        final shared = deck[i].toSet().intersection(deck[j].toSet());
        expect(shared.length, 1, reason: "cards $i and $j");
      }
    }
  });

  test("cards are sorted ascending", () {
    for (final card in deck) {
      final sorted = [...card]..sort();
      expect(card, sorted);
    }
  });
}
