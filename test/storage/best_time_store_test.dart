import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:tfi_bagundali/storage/best_time_store.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test("read returns null when nothing stored", () async {
    expect(await BestTimeStore().read(), isNull);
  });

  test("first submit becomes the best", () async {
    final store = BestTimeStore();
    expect(await store.submit(const Duration(seconds: 40)), isTrue);
    expect(await store.read(), const Duration(seconds: 40));
  });

  test("slower submit does not replace", () async {
    final store = BestTimeStore();
    await store.submit(const Duration(seconds: 30));
    expect(await store.submit(const Duration(seconds: 45)), isFalse);
    expect(await store.read(), const Duration(seconds: 30));
  });

  test("faster submit replaces", () async {
    final store = BestTimeStore();
    await store.submit(const Duration(seconds: 30));
    expect(
      await store.submit(const Duration(seconds: 21, milliseconds: 500)),
      isTrue,
    );
    expect(await store.read(), const Duration(seconds: 21, milliseconds: 500));
  });
}
