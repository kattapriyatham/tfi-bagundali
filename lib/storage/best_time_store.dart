import "package:shared_preferences/shared_preferences.dart";

class BestTimeStore {
  static const _key = "solo_best_time_ms";

  Future<Duration?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_key);
    return ms == null ? null : Duration(milliseconds: ms);
  }

  /// Writes [time] only if it beats the stored best (or none exists).
  /// Returns true when [time] became the new best.
  Future<bool> submit(Duration time) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key);
    if (current != null && current <= time.inMilliseconds) return false;
    await prefs.setInt(_key, time.inMilliseconds);
    return true;
  }
}
