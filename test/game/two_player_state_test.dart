import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/deck/deck_loader.dart";
import "package:tfi_bagundaali/deck/dobble.dart";
import "package:tfi_bagundaali/deck/match_rules.dart";
import "package:tfi_bagundaali/game/engine/two_player_state.dart";

void main() {
  final deck = deckFromRows(generateDobbleDeck(7));

  int matchFor(TwoPlayerState s, int player) => sharedSymbol(
        deck.card(s.heldFor(player)),
        deck.card(s.centerCardId),
      );

  test("startTwoPlayer deals a card each and points at the rest", () {
    final s = startTwoPlayer(1);
    expect(s.centerIndex, 2);
    expect(s.heldP1, s.deckOrder[0]);
    expect(s.heldP2, s.deckOrder[1]);
    expect(s.countP1, 0);
    expect(s.countP2, 0);
    expect(s.isComplete, isFalse);
  });

  test("a correct tap credits that player and rotates their card", () {
    final s = startTwoPlayer(2);
    final took = s.centerCardId;
    final next = applyTwoPlayerTap(
      state: s,
      player: 2,
      tappedSymbolId: matchFor(s, 2),
      deck: deck,
    );
    expect(next, isNotNull);
    expect(next!.countP2, 1);
    expect(next.countP1, 0);
    expect(next.heldP2, took);
    expect(next.centerIndex, 3);
  });

  test("a wrong tap returns null", () {
    final s = startTwoPlayer(3);
    final wrong = deck
        .card(s.heldP1)
        .symbolIds
        .firstWhere((x) => x != matchFor(s, 1));
    expect(
      applyTwoPlayerTap(
        state: s,
        player: 1,
        tappedSymbolId: wrong,
        deck: deck,
      ),
      isNull,
    );
  });

  test("racing to the end distributes all 55 central cards", () {
    var s = startTwoPlayer(4);
    var turn = 1;
    var guard = 0;
    while (!s.isComplete && guard++ < 200) {
      s = applyTwoPlayerTap(
        state: s,
        player: turn,
        tappedSymbolId: matchFor(s, turn),
        deck: deck,
      )!;
      turn = turn == 1 ? 2 : 1;
    }
    expect(s.isComplete, isTrue);
    expect(s.countP1 + s.countP2, 55);
    expect(s.winner, anyOf(0, 1, 2));
  });
}
