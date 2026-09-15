import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/deck/models.dart";

void main() {
  test("GameCard JSON round-trips", () {
    const card = GameCard(id: 3, symbolIds: [0, 1, 2, 3, 4, 5, 6, 7]);
    final json = card.toJson();
    expect(GameCard.fromJson(json), card);
  });

  test("SymbolPlacement JSON round-trips", () {
    const p = SymbolPlacement(
      symbolId: 9,
      x: 0.1,
      y: -0.4,
      scale: 1.05,
      rotationTurns: 0.25,
    );
    expect(SymbolPlacement.fromJson(p.toJson()), p);
  });

  test("value equality holds", () {
    expect(
      const GameCard(id: 1, symbolIds: [1, 2, 3, 4, 5, 6, 7, 8]),
      const GameCard(id: 1, symbolIds: [1, 2, 3, 4, 5, 6, 7, 8]),
    );
  });
}
