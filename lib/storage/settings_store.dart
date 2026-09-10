import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

@immutable
class Settings {
  const Settings({this.haptics = true, this.sound = false});

  final bool haptics;
  final bool sound;

  Settings copyWith({bool? haptics, bool? sound}) => Settings(
        haptics: haptics ?? this.haptics,
        sound: sound ?? this.sound,
      );

  @override
  bool operator ==(Object other) =>
      other is Settings && other.haptics == haptics && other.sound == sound;

  @override
  int get hashCode => Object.hash(haptics, sound);
}

class SettingsController extends Notifier<Settings> {
  static const _kHaptics = "settings_haptics";
  static const _kSound = "settings_sound";

  SharedPreferences? _prefs;

  @override
  Settings build() {
    _load();
    return const Settings();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = Settings(
      haptics: _prefs!.getBool(_kHaptics) ?? true,
      sound: _prefs!.getBool(_kSound) ?? false,
    );
  }

  Future<void> setHaptics({required bool enabled}) async {
    state = state.copyWith(haptics: enabled);
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setBool(_kHaptics, enabled);
  }

  Future<void> setSound({required bool enabled}) async {
    state = state.copyWith(sound: enabled);
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setBool(_kSound, enabled);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, Settings>(SettingsController.new);
