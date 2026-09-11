import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/core/online_availability.dart";

void main() {
  test("isOnlinePlatformSupported is true only on Android", () {
    expect(isOnlinePlatformSupported(platform: TargetPlatform.android), isTrue);
    expect(isOnlinePlatformSupported(platform: TargetPlatform.iOS), isFalse);
    expect(isOnlinePlatformSupported(platform: TargetPlatform.macOS), isFalse);
  });

  test("onlineAvailableProvider is false with no Firebase app initialized", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(onlineAvailableProvider), isFalse);
  });
}
