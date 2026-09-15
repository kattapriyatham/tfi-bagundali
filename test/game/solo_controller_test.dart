import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:tfi_bagundali/deck/deck_loader.dart";
import "package:tfi_bagundali/deck/dobble.dart";
import "package:tfi_bagundali/deck/match_rules.dart";
import "package:tfi_bagundali/game/engine/round_state.dart";
import "package:tfi_bagundali/game/solo/solo_controller.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final deck = deckFromRows(generateDobbleDeck(7));

  ProviderContainer makeContainer() {
    SharedPreferences.setMockInitialValues({});
    return ProviderContainer(
      overrides: [deckProvider.overrideWith((_) async => deck)],
    );
  }

  test("start deals a run with 56 cards left and a stopped clock", () async {
    final c = makeContainer();
    await c.read(deckProvider.future);
    c.read(soloControllerProvider.notifier).start(seed: 1);
    final v = c.read(soloControllerProvider);
    expect(v.cardsLeft, 56);
    expect(v.elapsed, Duration.zero);
    expect(v.complete, isFalse);
  });

  test("wrong tap records lastWrongSymbolId and does not advance", () async {
    final c = makeContainer();
    await c.read(deckProvider.future);
    final ctrl = c.read(soloControllerProvider.notifier)..start(seed: 2);
    final s = c.read(soloControllerProvider).round;
    final match =
        sharedSymbol(deck.card(s.heldCardId), deck.card(centerCardId(s)));
    final wrong =
        deck.card(s.heldCardId).symbolIds.firstWhere((x) => x != match);
    ctrl.tap(wrong);
    final v = c.read(soloControllerProvider);
    expect(v.lastWrongSymbolId, wrong);
    expect(v.cardsLeft, 56);
  });

  test("playing a full run completes and stores a best time", () async {
    final c = makeContainer();
    await c.read(deckProvider.future);
    var fakeNow = DateTime(2026);
    final ctrl = c.read(soloControllerProvider.notifier)
      ..start(seed: 3, clock: () => fakeNow);
    while (!c.read(soloControllerProvider).complete) {
      final s = c.read(soloControllerProvider).round;
      final match =
          sharedSymbol(deck.card(s.heldCardId), deck.card(centerCardId(s)));
      fakeNow = fakeNow.add(const Duration(seconds: 1));
      ctrl.tap(match);
    }
    await ctrl.committed;
    final v = c.read(soloControllerProvider);
    expect(v.complete, isTrue);
    expect(v.elapsed.inSeconds, greaterThan(0));
    expect(ctrl.isNewBest, isTrue);
  });
}
