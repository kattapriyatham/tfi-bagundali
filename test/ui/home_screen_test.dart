import "package:flutter/material.dart";
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
        ],
      );

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();
  }

  testWidgets("shows tagline, ad slot, and coming-soon menu items",
      (tester) async {
    await pumpHome(tester);

    expect(find.text("FOR THE LOVE OF TFI."), findsOneWidget);
    expect(find.byKey(const Key("ad-slot")), findsOneWidget);
    expect(find.text("Play Online"), findsOneWidget);
    expect(find.text("SOON"), findsNWidgets(3));
  });

  testWidgets("Play Solo navigates; Play Online does not", (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text("Play Online"));
    await tester.pumpAndSettle();
    expect(find.text("solo screen"), findsNothing);

    await tester.tap(find.text("Play Solo"));
    await tester.pumpAndSettle();
    expect(find.text("solo screen"), findsOneWidget);
  });
}
