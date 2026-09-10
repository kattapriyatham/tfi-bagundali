import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/deck/symbol_catalog.dart";

void main() {
  test("kSymbolCount is 57", () {
    expect(kSymbolCount, 57);
  });

  test("symbolArt is defined and stable for all 57 ids", () {
    for (var id = 0; id < kSymbolCount; id++) {
      final a = symbolArt(id);
      final b = symbolArt(id);
      expect(a, b);
      expect(a.label.length, inInclusiveRange(1, 2));
    }
  });

  test("adjacent ids differ visibly (shape or color)", () {
    for (var id = 0; id < kSymbolCount - 1; id++) {
      final a = symbolArt(id);
      final b = symbolArt(id + 1);
      expect(a.shape != b.shape || a.colorValue != b.colorValue, isTrue);
    }
  });
}
