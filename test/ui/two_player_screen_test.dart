import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:tfi_bagundaali/deck/deck_loader.dart";
import "package:tfi_bagundaali/deck/dobble.dart";
import "package:tfi_bagundaali/game/solo/solo_controller.dart" show deckProvider;
import "package:tfi_bagundaali/ui/two_player_screen.dart";

void main() {
  final deck = deckFromRows(generateDobbleDeck(7));

  testWidgets("countdown then two racing halves appear", (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(path: "/", builder: (_, __) => const TwoPlayerScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deckProvider.overrideWith((_) async => deck)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    expect(find.text("Player 1   0"), findsOneWidget);
    expect(find.text("Player 2   0"), findsOneWidget);
    expect(find.text("Same card. Find it first!"), findsNWidgets(2));
  });
}
