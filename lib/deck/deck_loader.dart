import "dart:convert";

import "package:flutter/services.dart" show AssetBundle, rootBundle;

import "deck.dart";

export "deck.dart" show Deck, deckFromRows;

/// Loads and parses `assets/deck.json` into a [Deck].
Future<Deck> loadDeck({AssetBundle? bundle}) async {
  final raw = await (bundle ?? rootBundle).loadString("assets/deck.json");
  final rows = (jsonDecode(raw) as List<dynamic>)
      .map((row) => (row as List<dynamic>).cast<int>())
      .toList();
  return deckFromRows(rows);
}
