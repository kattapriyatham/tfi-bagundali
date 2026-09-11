import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:tfi_bagundaali/ui/home_screen.dart";

void main() {
  GoRouter buildRouter() => GoRouter(
        routes: [
          GoRoute(path: "/", builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: "/solo",
            builder: (_, __) => const Scaffold(body: Text("solo screen")),
          ),
          GoRoute(
            path: "/two-player",
            builder: (_, __) => const Scaffold(body: Text("2p screen")),
          ),
          GoRoute(
            path: "/settings",
            builder: (_, __) => const Scaffold(body: Text("settings screen")),
          ),
        ],
      );

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: buildRouter()),
      ),
    );
    await tester.pump();
  }

  testWidgets("shows tagline, ad slot, and coming-soon menu items",
      (tester) async {
    await pumpHome(tester);

    expect(find.text("FOR THE LOVE OF TFI."), findsOneWidget);
    expect(find.byKey(const Key("ad-slot")), findsOneWidget);
    expect(find.text("Play Online"), findsOneWidget);
    expect(find.text("SOON"), findsOneWidget);
  });

  testWidgets("Play Solo and 2-Player navigate; Play Online does not",
      (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text("Play Online"));
    await tester.pumpAndSettle();
    expect(find.text("solo screen"), findsNothing);

    // The menu is a horizontal strip — scroll "2-Player" into view first.
    await tester.dragUntilVisible(
      find.text("2-Player"),
      find.byType(ListView),
      const Offset(-200, 0),
    );
    await tester.tap(find.text("2-Player"));
    await tester.pumpAndSettle();
    expect(find.text("2p screen"), findsOneWidget);
  });

  testWidgets("Play Solo navigates", (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text("Play Solo"));
    await tester.pumpAndSettle();
    expect(find.text("solo screen"), findsOneWidget);
  });
}
