import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/deck/dobble.dart";

void main() {
  test("assets/deck.json matches the generator output", () {
    final onDisk = jsonDecode(File("assets/deck.json").readAsStringSync())
        as List<dynamic>;
    final decoded = onDisk
        .map((row) => (row as List<dynamic>).cast<int>())
        .toList();
    expect(
      decoded,
      generateDobbleDeck(7),
      reason: "run: dart run tool/generate_deck_json.dart",
    );
  });
}
