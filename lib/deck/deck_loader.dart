import "dart:convert";

import "package:flutter/services.dart" show AssetBundle, rootBundle;

import "models.dart";

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

Future<Deck> loadDeck({AssetBundle? bundle}) async {
  final raw = await (bundle ?? rootBundle).loadString("assets/deck.json");
  final rows = (jsonDecode(raw) as List<dynamic>)
      .map((row) => (row as List<dynamic>).cast<int>())
      .toList();
  return deckFromRows(rows);
}
