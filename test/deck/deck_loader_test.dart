import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/deck/deck_loader.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("deckFromRows builds indexed cards", () {
    final deck = deckFromRows([
      [0, 1, 2, 3, 4, 5, 6, 7],
      [0, 8, 9, 10, 11, 12, 13, 14],
    ]);
    expect(deck.cards.length, 2);
    expect(deck.card(1).symbolIds.first, 0);
    expect(deck.card(0).id, 0);
  });

  test("loadDeck parses the bundled asset into 57 cards", () async {
    final deck = await loadDeck(bundle: rootBundle);
    expect(deck.cards.length, 57);
    expect(deck.card(56).symbolIds.length, 8);
  });
}
