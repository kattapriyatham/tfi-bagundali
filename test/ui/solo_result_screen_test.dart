import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:tfi_bagundaali/ui/solo_result_screen.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("shows a stored best time and Play Again navigates to /solo",
      (tester) async {
    SharedPreferences.setMockInitialValues({"solo_best_time_ms": 41000});
    var went = "";
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/solo/result",
          builder: (_, __) => const SoloResultScreen(),
        ),
        GoRoute(
          path: "/solo",
          builder: (_, __) {
            went = "/solo";
            return const Scaffold(body: Text("solo"));
          },
        ),
        GoRoute(
          path: "/",
          builder: (_, __) {
            went = "/";
            return const Scaffold(body: Text("home"));
          },
        ),
      ],
      initialLocation: "/solo/result",
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("Best"), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, "Play Again"));
    await tester.pumpAndSettle();
    expect(went, "/solo");
  });
}
