import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:tfi_bagundaali/ui/home_screen.dart";

void main() {
  testWidgets("shows tagline, a working Play Solo, and disabled online",
      (tester) async {
    String? location;
    final router = GoRouter(
      routes: [
        GoRoute(path: "/", builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: "/solo",
          builder: (_, __) {
            location = "/solo";
            return const Scaffold(body: Text("solo"));
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text("Spot the one. For the love of TFI."), findsOneWidget);
    expect(find.byKey(const Key("ad-slot")), findsOneWidget);

    final online = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, "Play Online"),
    );
    expect(online.onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, "Play Solo"));
    await tester.pumpAndSettle();
    expect(location, "/solo");
  });
}
