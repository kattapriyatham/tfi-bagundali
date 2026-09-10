/// Generates a Dobble/Spot-It deck from the finite projective plane of
/// order [n]. [n] must be prime (this app uses 7).
///
/// Returns `n*n + n + 1` cards; each card has `n + 1` symbol ids in the
/// range `0 .. n*n + n`. Any two cards share exactly one symbol.
List<List<int>> generateDobbleDeck(int n) {
  final cards = <List<int>>[];

  // Card 0: the n+1 "first group" symbols 0..n.
  cards.add([for (var i = 0; i <= n; i++) i]);

  // n cards: first-group symbol 0 with each full block of the n*n others.
  for (var i = 0; i < n; i++) {
    cards.add([
      0,
      for (var j = 0; j < n; j++) n + 1 + n * i + j,
    ]);
  }

  // n*n cards: first-group symbol (i+1) with one symbol from every block.
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < n; j++) {
      cards.add([
        i + 1,
        for (var k = 0; k < n; k++) n + 1 + n * k + ((i * k + j) % n),
      ]);
    }
  }

  for (final card in cards) {
    card.sort();
  }
  return cards;
}
