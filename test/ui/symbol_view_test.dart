import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/ui/widgets/symbol_view.dart";

void main() {
  testWidgets("renders at the requested size for every symbol id",
      (tester) async {
    for (final id in [0, 12, 34, 56]) {
      await tester.pumpWidget(
        MaterialApp(home: Center(child: SymbolView(symbolId: id, size: 40))),
      );
      final size = tester.getSize(find.byType(SymbolView));
      expect(size, const Size(40, 40));
    }
  });
}
