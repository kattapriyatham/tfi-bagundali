import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/core/rng.dart";

void main() {
  test("same seed produces the same sequence", () {
    final a = SeededRng(42);
    final b = SeededRng(42);
    final seqA = List.generate(20, (_) => a.nextDouble());
    final seqB = List.generate(20, (_) => b.nextDouble());
    expect(seqA, seqB);
  });

  test("different seeds diverge", () {
    final a = SeededRng(1);
    final b = SeededRng(2);
    expect(a.nextDouble(), isNot(b.nextDouble()));
  });

  test("nextDouble stays in [0, 1)", () {
    final r = SeededRng(7);
    for (var i = 0; i < 1000; i++) {
      final v = r.nextDouble();
      expect(v, greaterThanOrEqualTo(0.0));
      expect(v, lessThan(1.0));
    }
  });

  test("nextInt stays in [0, max)", () {
    final r = SeededRng(7);
    for (var i = 0; i < 1000; i++) {
      final v = r.nextInt(13);
      expect(v, greaterThanOrEqualTo(0));
      expect(v, lessThan(13));
    }
  });
}
