import "dart:convert";
import "dart:io";

import "package:tfi_bagundali/deck/dobble.dart";

/// Regenerates assets/deck.json. Run: `dart run tool/generate_deck_json.dart`
void main() {
  final deck = generateDobbleDeck(7);
  const encoder = JsonEncoder.withIndent("  ");
  File("assets/deck.json").writeAsStringSync("${encoder.convert(deck)}\n");
  stdout.writeln("Wrote assets/deck.json (${deck.length} cards)");
}
