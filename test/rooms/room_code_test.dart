import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/rooms/room_code.dart";

void main() {
  test("generates a 5-character code from the fixed alphabet", () {
    final code = generateRoomCode(Random(1));
    expect(code.length, 5);
    expect(code.split("").every(kRoomCodeAlphabet.contains), isTrue);
  });

  test("excludes ambiguous characters", () {
    expect(kRoomCodeAlphabet.contains("I"), isFalse);
    expect(kRoomCodeAlphabet.contains("O"), isFalse);
    expect(kRoomCodeAlphabet.contains("0"), isFalse);
    expect(kRoomCodeAlphabet.contains("1"), isFalse);
  });

  test("is deterministic for a given seeded Random", () {
    expect(generateRoomCode(Random(42)), generateRoomCode(Random(42)));
  });
}
