import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Persists the room code of a game the player is currently in, so the app
/// can offer a way back in if it's backgrounded or killed mid-game (spec
/// gap: without this there's no path back to a joined room after restart).
class ActiveRoomController extends Notifier<String?> {
  static const _kCode = "active_room_code";

  SharedPreferences? _prefs;

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs!.getString(_kCode);
  }

  /// Reads the stored code directly, without waiting on [build]'s own load
  /// (and without the ordering games that would take) — for a one-off check
  /// right at startup, such as the home screen's "rejoin" banner.
  Future<String?> readStored() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    return prefs.getString(_kCode);
  }

  Future<void> save(String code) async {
    state = code;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_kCode, code);
  }

  Future<void> clear() async {
    state = null;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(_kCode);
  }
}

final activeRoomProvider =
    NotifierProvider<ActiveRoomController, String?>(ActiveRoomController.new);
