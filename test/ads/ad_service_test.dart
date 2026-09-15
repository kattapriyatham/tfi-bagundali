import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundali/ads/ad_service.dart";

void main() {
  test("a debug-build AdService is inert and never throws", () async {
    final svc = AdService(); // debug builds default to disabled
    await svc.init();
    svc
      ..showInterstitial()
      ..showColdOpenInterstitial()
      ..showColdOpenInterstitial();
    expect(svc.enabled, isFalse);
  });
}
