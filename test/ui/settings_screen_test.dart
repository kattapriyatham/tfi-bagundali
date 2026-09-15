import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:tfi_bagundali/storage/settings_store.dart";
import "package:tfi_bagundali/ui/settings_screen.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("toggling Haptics persists to the store", (tester) async {
    SharedPreferences.setMockInitialValues({});
    final router = GoRouter(
      routes: [
        GoRoute(path: "/", builder: (_, __) => const SettingsScreen()),
        GoRoute(
          path: "/settings",
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).haptics, isTrue);
    await tester.tap(find.text("Haptics"));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).haptics, isFalse);
  });
}
