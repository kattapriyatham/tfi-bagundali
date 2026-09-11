import "dart:math";

const kRoomCodeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ";
const _kRoomCodeLength = 5;

/// A 5-character room code drawn from [kRoomCodeAlphabet] (26 letters minus
/// `I`/`O`, which are visually confusable with `1`/`0`).
String generateRoomCode(Random random) => List.generate(
      _kRoomCodeLength,
      (_) => kRoomCodeAlphabet[random.nextInt(kRoomCodeAlphabet.length)],
    ).join();
