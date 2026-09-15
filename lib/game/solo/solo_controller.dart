import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../deck/deck_loader.dart";
import "../../storage/best_time_store.dart";
import "../engine/round_state.dart";

final deckProvider = FutureProvider<Deck>((ref) => loadDeck());

@immutable
class SoloView {
  const SoloView({
    required this.round,
    required this.elapsed,
    required this.lastWrongSymbolId,
    required this.complete,
  });

  final RoundState round;
  final Duration elapsed;
  final int? lastWrongSymbolId;
  final bool complete;

  int get cardsLeft => round.deckOrder.length - round.centerIndex;

  SoloView copyWith({
    RoundState? round,
    Duration? elapsed,
    int? lastWrongSymbolId,
    bool clearWrong = false,
    bool? complete,
  }) {
    return SoloView(
      round: round ?? this.round,
      elapsed: elapsed ?? this.elapsed,
      lastWrongSymbolId:
          clearWrong ? null : (lastWrongSymbolId ?? this.lastWrongSymbolId),
      complete: complete ?? this.complete,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SoloView &&
      other.round == round &&
      other.elapsed == elapsed &&
      other.lastWrongSymbolId == lastWrongSymbolId &&
      other.complete == complete;

  @override
  int get hashCode => Object.hash(round, elapsed, lastWrongSymbolId, complete);
}

class SoloController extends Notifier<SoloView> {
  DateTime Function() _clock = DateTime.now;
  DateTime? _firstTapAt;
  DateTime? _lockUntil;
  bool _isNewBest = false;
  Future<void>? _commitFuture;
  final BestTimeStore _store = BestTimeStore();

  bool get isNewBest => _isNewBest;

  /// When the current run's timer started (round start), or null before a
  /// round has been started. Exposed so the UI can tick a live stopwatch
  /// between correct taps — [SoloView.elapsed] itself only updates on a
  /// correct tap.
  DateTime? get firstTapAt => _firstTapAt;

  /// Completes once the finished run's best time has been persisted.
  Future<void> get committed => _commitFuture ?? Future<void>.value();

  @override
  SoloView build() => SoloView(
        round: startRun(shuffledDeckOrder(0)),
        elapsed: Duration.zero,
        lastWrongSymbolId: null,
        complete: false,
      );

  void start({int? seed, DateTime Function()? clock}) {
    _clock = clock ?? DateTime.now;
    _firstTapAt = _clock();
    _lockUntil = null;
    _isNewBest = false;
    _commitFuture = null;
    state = SoloView(
      round:
          startRun(shuffledDeckOrder(seed ?? _clock().millisecondsSinceEpoch)),
      elapsed: Duration.zero,
      lastWrongSymbolId: null,
      complete: false,
    );
  }

  Deck get _deck => ref.read(deckProvider).requireValue;

  void tap(int symbolId) {
    if (state.complete) return;
    final now = _clock();
    if (_lockUntil != null && now.isBefore(_lockUntil!)) return;
    _firstTapAt ??= now; // safety net: start() always sets this already

    final next =
        applyTap(state: state.round, tappedSymbolId: symbolId, deck: _deck);
    if (next == null) {
      _lockUntil = now.add(const Duration(milliseconds: 500));
      state = state.copyWith(lastWrongSymbolId: symbolId);
      return;
    }

    // Debounce: a finger still resting near the card must not immediately
    // register a stray tap on the next card.
    _lockUntil = now.add(const Duration(milliseconds: 250));

    final elapsed = now.difference(_firstTapAt!);
    final done = isComplete(next);
    state = state.copyWith(
      round: next,
      elapsed: elapsed,
      clearWrong: true,
      complete: done,
    );
    if (done) {
      _commitFuture = _store.submit(elapsed).then((isBest) {
        _isNewBest = isBest;
      });
    }
  }
}

final soloControllerProvider =
    NotifierProvider<SoloController, SoloView>(SoloController.new);
