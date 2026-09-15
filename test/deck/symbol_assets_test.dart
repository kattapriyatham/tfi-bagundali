import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/deck/symbol_assets.dart";
import "package:tfi_bagundali/deck/symbol_catalog.dart";

void main() {
  test("there is one asset slot per symbol", () {
    expect(kSymbolAssets.length, kSymbolCount);
  });

  test("every non-null asset path points at a file that exists", () {
    for (final path in kSymbolAssets) {
      if (path == null) continue;
      expect(File(path).existsSync(), isTrue, reason: "missing $path");
    }
  });

  test("at most one symbol falls back to the painted placeholder", () {
    expect(kSymbolAssets.where((p) => p == null).length, lessThanOrEqualTo(1));
  });
}
