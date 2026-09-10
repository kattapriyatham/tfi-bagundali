import "models.dart";

/// The single symbol id present on both [a] and [b].
int sharedSymbol(GameCard a, GameCard b) {
  final common = a.symbolIds.toSet().intersection(b.symbolIds.toSet());
  if (common.length != 1) {
    throw StateError(
      "cards ${a.id} and ${b.id} share ${common.length} symbols, expected 1",
    );
  }
  return common.first;
}

bool isMatch(GameCard a, GameCard b, int symbolId) =>
    symbolId == sharedSymbol(a, b);
