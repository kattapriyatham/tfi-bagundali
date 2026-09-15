import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:tfi_bagundali/deck/deck_loader.dart";
import "package:tfi_bagundali/deck/dobble.dart";
import "package:tfi_bagundali/game/solo/solo_controller.dart" show deckProvider;
import "package:tfi_bagundali/ui/two_player_screen.dart";
import "package:tfi_bagundali/ui/widgets/card_view.dart";

void main() {
  final deck = deckFromRows(generateDobbleDeck(7));

  testWidgets("countdown then both player cards and centre appear",
      (tester) async {
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

    expect(find.text("Player 1"), findsOneWidget);
    expect(find.text("Player 2"), findsOneWidget);
    expect(find.byType(CardView), findsNWidgets(3));
  });
}
