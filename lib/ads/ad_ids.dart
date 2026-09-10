import "dart:io";

/// AdMob unit ids.
///
/// TODO(owner): before store release, replace every value below with the
/// real ids from the project's AdMob account, and swap the native app ids:
///   - android/app/src/main/AndroidManifest.xml  (APPLICATION_ID meta-data)
///   - ios/Runner/Info.plist                      (GADApplicationIdentifier)
/// These are Google's public test ids and only ever serve test ads.
abstract final class AdIds {
  static String get banner => Platform.isIOS
      ? "ca-app-pub-3940256099942544/2934735716"
      : "ca-app-pub-3940256099942544/6300978111";

  static String get interstitial => Platform.isIOS
      ? "ca-app-pub-3940256099942544/4411468910"
      : "ca-app-pub-3940256099942544/1033173712";
}
