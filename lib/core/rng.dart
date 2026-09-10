/// Deterministic pseudo-random generator (mulberry32).
///
/// Assumes 64-bit native integers (mobile only); not web-safe.
class SeededRng {
  SeededRng(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  /// Uniform double in [0, 1).
  double nextDouble() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = ((t ^ (t >>> 15)) * (t | 1)) & 0xFFFFFFFF;
    t ^= (t + ((t ^ (t >>> 7)) * (t | 61))) & 0xFFFFFFFF;
    t = (t ^ (t >>> 14)) & 0xFFFFFFFF;
    return t / 0x100000000;
  }

  /// Uniform int in [0, max).
  int nextInt(int max) {
    assert(max > 0, "max must be positive");
    return (nextDouble() * max).floor();
  }
}
