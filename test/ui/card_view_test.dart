import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/deck/deck_loader.dart";
import "package:tfi_bagundali/deck/dobble.dart";
import "package:tfi_bagundali/ui/widgets/card_view.dart";
import "package:tfi_bagundali/ui/widgets/symbol_view.dart";

void main() {
  final deck = deckFromRows(generateDobbleDeck(7));

  testWidgets("renders 8 symbols and reports the tapped one", (tester) async {
    final card = deck.card(10);
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CardView(
              card: card,
              diameter: 360,
              onSymbolTap: taps.add,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SymbolView), findsNWidgets(8));

    await tester.tap(
      find.byKey(ValueKey("symbol-${card.symbolIds[3]}")),
      warnIfMissed: false,
    );
    expect(taps, [card.symbolIds[3]]);
  });

  testWidgets("interactive:false swallows taps", (tester) async {
    final card = deck.card(4);
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CardView(
              card: card,
              interactive: false,
              onSymbolTap: taps.add,
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(ValueKey("symbol-${card.symbolIds.first}")),
      warnIfMissed: false,
    );
    expect(taps, isEmpty);
  });
}
