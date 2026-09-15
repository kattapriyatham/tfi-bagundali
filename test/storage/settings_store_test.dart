import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:tfi_bagundali/storage/settings_store.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("defaults: haptics on, sound off", () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    expect(c.read(settingsProvider), const Settings());
    await c.read(settingsProvider.notifier).setHaptics(enabled: false);
    expect(c.read(settingsProvider).haptics, isFalse);
  });

  test("a saved value is read back on the next container", () async {
    SharedPreferences.setMockInitialValues({"settings_haptics": false});
    final c = ProviderContainer();
    // trigger the async load
    c.read(settingsProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(settingsProvider).haptics, isFalse);
  });
}
