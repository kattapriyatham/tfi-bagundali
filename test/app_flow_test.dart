import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:tfi_bagundali/app.dart";
import "package:tfi_bagundali/deck/deck_loader.dart";
import "package:tfi_bagundali/deck/dobble.dart";
import "package:tfi_bagundali/deck/match_rules.dart";
import "package:tfi_bagundali/game/engine/round_state.dart";
import "package:tfi_bagundali/game/solo/solo_controller.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final deck = deckFromRows(generateDobbleDeck(7));

  testWidgets("home -> solo -> finish -> result", (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deckProvider.overrideWith((_) async => deck)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Play Solo"));
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final ctrl = container.read(soloControllerProvider.notifier);
    // Re-seed with a fake advancing clock so the tap debounce never blocks
    // the driven run.
    var now = DateTime(2026);
    ctrl.start(seed: 7, clock: () => now);
    var guard = 0;
    while (!container.read(soloControllerProvider).complete && guard++ < 100) {
      final s = container.read(soloControllerProvider).round;
      final match = sharedSymbol(
        deck.card(s.heldCardId),
        deck.card(centerCardId(s)),
      );
      now = now.add(const Duration(seconds: 1));
      ctrl.tap(match);
    }
    await ctrl.committed;
    await tester.pumpAndSettle();

    expect(find.text("YOU DID IT!"), findsOneWidget);
  });
}
