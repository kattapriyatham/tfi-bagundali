import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:tfi_bagundaali/deck/deck_loader.dart";
import "package:tfi_bagundaali/deck/dobble.dart";
import "package:tfi_bagundaali/game/solo/solo_controller.dart";
import "package:tfi_bagundaali/ui/solo_game_screen.dart";

void main() {
  final deck = deckFromRows(generateDobbleDeck(7));

  testWidgets("countdown then playing state, 56 cards left", (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: "/", builder: (_, __) => const SoloGameScreen()),
        GoRoute(
          path: "/solo/result",
          builder: (_, __) => const Scaffold(body: Text("result")),
        ),
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

    expect(find.text("Cards Left"), findsOneWidget);
    expect(find.text("56"), findsOneWidget);
  });
}
