import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/deck/deck_loader.dart";
import "package:tfi_bagundaali/deck/dobble.dart";
import "package:tfi_bagundaali/deck/match_rules.dart";
import "package:tfi_bagundaali/game/engine/two_player_state.dart";
import "package:tfi_bagundaali/game/local/two_player_controller.dart";
import "package:tfi_bagundaali/game/solo/solo_controller.dart" show deckProvider;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final deck = deckFromRows(generateDobbleDeck(7));

  ProviderContainer make() => ProviderContainer(
        overrides: [deckProvider.overrideWith((_) async => deck)],
      );

  int matchFor(TwoPlayerState s, int p) => sharedSymbol(
        deck.card(s.heldFor(p)),
        deck.card(s.centerCardId),
      );

  test("wrong tap flags only that player and does not advance", () async {
    final c = make();
    await c.read(deckProvider.future);
    final ctrl = c.read(twoPlayerControllerProvider.notifier)..start(seed: 1);
    final s = c.read(twoPlayerControllerProvider).state;
    final wrong =
        deck.card(s.heldP1).symbolIds.firstWhere((x) => x != matchFor(s, 1));
    ctrl.tap(1, wrong);
    final v = c.read(twoPlayerControllerProvider);
    expect(v.wrongP1, wrong);
    expect(v.wrongP2, isNull);
    expect(v.state.centerIndex, 2);
  });

  test("both players racing finish the pile and set a winner", () async {
    final c = make();
    await c.read(deckProvider.future);
    var now = DateTime(2026);
    final ctrl = c.read(twoPlayerControllerProvider.notifier)
      ..start(seed: 5, clock: () => now);
    var turn = 1;
    var guard = 0;
    bool done() => c.read(twoPlayerControllerProvider).state.isComplete;
    while (!done() && guard++ < 200) {
      final s = c.read(twoPlayerControllerProvider).state;
      now = now.add(const Duration(seconds: 1));
      ctrl.tap(turn, matchFor(s, turn));
      turn = turn == 1 ? 2 : 1;
    }
    final st = c.read(twoPlayerControllerProvider).state;
    expect(st.isComplete, isTrue);
    expect(st.countP1 + st.countP2, 55);
  });
}
