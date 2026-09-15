# Play Store Launch Checklist

## Build / signing
- [x] Generate upload keystore — `~/keystores/tfibagundali-upload.jks` (outside repo, alias `upload`; **back this up**, losing it means losing ability to update the app)
- [x] Create `android/key.properties`, wire real `signingConfig` in [android/app/build.gradle.kts](android/app/build.gradle.kts)
- [ ] Bump `version` in [pubspec.yaml](pubspec.yaml) per release (currently `0.1.0+1`)
- [x] Confirm Firebase wiring — no `google-services.json` needed, project uses [lib/core/firebase_options.dart](lib/core/firebase_options.dart) (FlutterFire Dart config), single project `spndex-37b0d`, matches `.firebaserc`
- [x] Replace AdMob test app ID in [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) with real one (Android done; iOS still test id, pending iOS AdMob app)
- [x] Swap real Android banner/interstitial ad-unit ids in [lib/ads/ad_ids.dart](lib/ads/ad_ids.dart)
- [x] Build release AAB: `flutter build appbundle --release` — builds and signs correctly with upload key (verified via `jarsigner -verify`)
- [ ] (optional) Install Android SDK `cmdline-tools` so native debug symbols strip cleanly — currently non-fatal warning, only affects native-crash symbolication quality

## Firebase / backend
- [ ] Verify Firebase Auth/Firestore/RTDB still work on-device after the `io.tfibagundaali.app` → `io.tfibagundali.app` applicationId rename — the Firebase app is registered under the old package name; if the Google Cloud API key has Android package/SHA1 restrictions, requests will fail until that's updated in the Firebase/Google Cloud console
- [x] Lock down `firestore.rules` — auth-gated, owner-only, no dev-open rules
- [x] Lock down `database.rules.json` (Realtime DB, online rooms) — auth-gated, no dev-open rules
- [x] Confirm Firebase project is production, not dev/test — `spndex-37b0d` confirmed production

## Play Console — account & app setup
- [x] Google Play Developer account ($25 one-time)
- [ ] Create app, set default language, app name, short/full description
- [ ] App category + tags

## Store listing assets
- [ ] App icon (512x512)
- [ ] Feature graphic (1024x500)
- [ ] Phone screenshots (min 2, up to 8)
- [ ] Tablet screenshots (optional)
- [ ] Promo video (optional)

## Policy / compliance
- [x] Privacy policy drafted — [PRIVACY_POLICY.md](PRIVACY_POLICY.md), styled copy at [web/privacy.html](web/privacy.html)
- [x] Deploy [web/](web) to Vercel — live at https://tfi-bagundali.vercel.app/ (privacy: https://tfi-bagundali.vercel.app/privacy.html); still needs pasting into Play Console data-safety + account-deletion forms
- [ ] Data safety form in Play Console
- [ ] Ads declaration (AdMob)
- [ ] Content rating questionnaire (IARC)
- [ ] Target audience / age group declaration
- [x] In-app account deletion flow — "Delete my data" in [settings_screen.dart](lib/ui/settings_screen.dart), see [account_deletion.dart](lib/auth/account_deletion.dart)
- [x] Wire the in-app "Privacy policy" tile to open the live URL — [settings_screen.dart](lib/ui/settings_screen.dart) now opens https://tfi-bagundali.vercel.app/privacy.html via `url_launcher`

## Release
- [ ] Internal testing track
- [ ] Closed/open testing (optional)
- [ ] Production rollout (staged, e.g. 20%)
