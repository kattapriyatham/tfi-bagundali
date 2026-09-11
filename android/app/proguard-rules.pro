# R8 rules for the release build.
#
# WorkManager (pulled in transitively by google_mobile_ads) uses Room, which
# creates its generated *_Impl classes by reflection at runtime. Without
# these keep rules R8 strips/renames them and the app crashes on launch with
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class * { *; }
-dontwarn androidx.work.**

# Google Mobile Ads (AdMob) SDK.
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
