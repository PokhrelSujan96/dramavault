class DoubleTapDetector {
  DoubleTapDetector({
    this.window = const Duration(milliseconds: 280),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration window;
  final DateTime Function() _clock;
  DateTime? _last;

  bool register() {
    final now = _clock();
    final isDouble = _last != null && now.difference(_last!) < window;
    _last = isDouble ? null : now;
    return isDouble;
  }
}
