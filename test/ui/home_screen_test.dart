import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:tfi_bagundaali/core/online_availability.dart";
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

  Future<void> pumpHome(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: buildRouter()),
      ),
    );
    await tester.pump();
  }

  testWidgets("shows tagline, ad slot, settings icon, and a coming-soon mode",
      (tester) async {
    await pumpHome(tester);

    expect(find.text("FOR THE LOVE OF TFI."), findsOneWidget);
    expect(find.byKey(const Key("ad-slot")), findsOneWidget);
    expect(find.text("Play Online"), findsOneWidget);
    expect(find.text("SOON"), findsOneWidget);
    expect(find.byTooltip("Settings"), findsOneWidget);
  });

  testWidgets("Play Solo and 2-Player navigate; Play Online does not",
      (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text("Play Online"));
    await tester.pumpAndSettle();
    expect(find.text("solo screen"), findsNothing);

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

  testWidgets("Settings icon navigates", (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byTooltip("Settings"));
    await tester.pumpAndSettle();
    expect(find.text("settings screen"), findsOneWidget);
  });

  testWidgets("Play Online is enabled when onlineAvailableProvider is true",
      (tester) async {
    await pumpHome(
      tester,
      overrides: [onlineAvailableProvider.overrideWithValue(true)],
    );
    expect(find.text("SOON"), findsNothing);
  });
}
