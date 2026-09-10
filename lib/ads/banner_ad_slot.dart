import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_mobile_ads/google_mobile_ads.dart";

import "../core/theme.dart";
import "ad_ids.dart";
import "ad_service.dart";

/// A fixed-height banner slot for static screens. Renders an empty sand
/// bar until (and unless) an ad loads, so layout never jumps.
class BannerAdSlot extends ConsumerStatefulWidget {
  const BannerAdSlot({super.key});

  static const double height = 56;

  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!ref.read(adServiceProvider).enabled) return;
    try {
      final ad = BannerAd(
        adUnitId: AdIds.banner,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) => ad.dispose(),
        ),
      )..load();
      _ad = ad;
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key("ad-slot"),
      height: BannerAdSlot.height,
      width: double.infinity,
      alignment: Alignment.center,
      color: AppColors.sand,
      child: _loaded && _ad != null
          ? SizedBox(
              width: _ad!.size.width.toDouble(),
              height: _ad!.size.height.toDouble(),
              child: AdWidget(ad: _ad!),
            )
          : null,
    );
  }
}
