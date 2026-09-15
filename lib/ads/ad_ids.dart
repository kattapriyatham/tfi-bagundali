import "dart:io";

/// AdMob unit ids.
///
/// TODO(owner): iOS still on Google's public test ids — replace once an iOS
/// AdMob app + ad units exist, and swap the app id in ios/Runner/Info.plist
/// (GADApplicationIdentifier).
abstract final class AdIds {
  static String get banner => Platform.isIOS
      ? "ca-app-pub-3940256099942544/2934735716"
      : "ca-app-pub-1604142696504342/7827771088";

  static String get interstitial => Platform.isIOS
      ? "ca-app-pub-3940256099942544/4411468910"
      : "ca-app-pub-1604142696504342/6896253785";
}
