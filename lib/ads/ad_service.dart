import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_mobile_ads/google_mobile_ads.dart";

import "ad_ids.dart";

/// Thin wrapper around AdMob. Every failure is swallowed: no ad simply
/// means no-op, and the game never blocks waiting on one.
///
/// Placements (see the design spec): a banner on static screens only
/// (home, results) and an interstitial on cold app open and when a full
/// game ends. Never during or between rounds.
class AdService {
  AdService({this.enabled = !kDebugMode});

  /// Ads are disabled in debug builds by default so tests and local runs
  /// stay quiet; release builds serve (test) ads.
  final bool enabled;

  bool _initialised = false;
  InterstitialAd? _interstitial;
  bool _coldOpenShown = false;

  Future<void> init() async {
    if (!enabled || _initialised) return;
    _initialised = true;
    try {
      await MobileAds.instance.initialize();
      _preloadInterstitial();
    } catch (_) {
      // ignore
    }
  }

  void _preloadInterstitial() {
    if (!enabled) return;
    try {
      InterstitialAd.load(
        adUnitId: AdIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _interstitial = ad,
          onAdFailedToLoad: (_) => _interstitial = null,
        ),
      );
    } catch (_) {
      // ignore
    }
  }

  /// Shows the interstitial if one is ready, then reloads. No-op otherwise.
  void showInterstitial() {
    if (!enabled) return;
    final ad = _interstitial;
    if (ad == null) {
      _preloadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _preloadInterstitial();
      },
    );
    ad.show();
  }

  /// Shows the cold-open interstitial at most once per process.
  void showColdOpenInterstitial() {
    if (_coldOpenShown) return;
    _coldOpenShown = true;
    showInterstitial();
  }
}

final adServiceProvider = Provider<AdService>((ref) => AdService()..init());
