import "models.dart";

/// An in-memory deck: the 57 cards plus id lookup. Pure; no asset loading.
class Deck {
  Deck(this.cards) : _byId = {for (final c in cards) c.id: c};

  final List<GameCard> cards;
  final Map<int, GameCard> _byId;

  GameCard card(int id) {
    final c = _byId[id];
    if (c == null) throw ArgumentError("no card with id $id");
    return c;
  }
}

Deck deckFromRows(List<List<int>> rows) {
  final cards = <GameCard>[];
  for (var i = 0; i < rows.length; i++) {
    cards.add(GameCard(id: i, symbolIds: rows[i]));
  }
  return Deck(cards);
}
