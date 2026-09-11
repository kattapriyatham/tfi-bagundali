import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/deck/card_layout.dart";
import "package:tfi_bagundaali/deck/deck_loader.dart";
import "package:tfi_bagundaali/deck/dobble.dart";

void main() {
  final deck = deckFromRows(generateDobbleDeck(7));

  test("layout is deterministic per card id", () {
    for (final card in deck.cards) {
      expect(layoutForCard(card), layoutForCard(card));
    }
  });

  test("every symbol on the card appears exactly once in the layout", () {
    for (final card in deck.cards) {
      final placed = layoutForCard(card).map((p) => p.symbolId).toList()
        ..sort();
      final expected = [...card.symbolIds]..sort();
      expect(placed, expected);
    }
  });

  test("all placements stay inside the unit card", () {
    for (final card in deck.cards) {
      for (final p in layoutForCard(card)) {
        final reach = sqrt(p.x * p.x + p.y * p.y) + kSymbolRadius * p.scale;
        expect(reach, lessThanOrEqualTo(1.001), reason: "card ${card.id}");
        expect(p.scale, inInclusiveRange(0.82, 1.25));
        expect(p.rotationTurns, inInclusiveRange(0.0, 1.0));
      }
    }
  });

  test("symbols do not grossly overlap", () {
    for (final card in deck.cards) {
      final ps = layoutForCard(card);
      for (var i = 0; i < ps.length; i++) {
        for (var j = i + 1; j < ps.length; j++) {
          final dx = ps[i].x - ps[j].x;
          final dy = ps[i].y - ps[j].y;
          final dist = sqrt(dx * dx + dy * dy);
          final ri = kSymbolRadius * ps[i].scale;
          final rj = kSymbolRadius * ps[j].scale;
          final minGap = (ri + rj) * 0.62;
          expect(dist, greaterThanOrEqualTo(minGap), reason: "card ${card.id}");
        }
      }
    }
  });
}
