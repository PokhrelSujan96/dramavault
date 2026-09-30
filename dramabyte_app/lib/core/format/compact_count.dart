String compactCount(int value) {
  if (value < 1000) return '$value';
  const units = [(1e9, 'B'), (1e6, 'M'), (1e3, 'K')];
  for (final (size, suffix) in units) {
    if (value >= size) {
      final scaled = (value / size * 100).floor() / 100;
      final text = scaled
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'\.?0+$'), '');
      return '$text$suffix';
    }
  }
  return '$value';
}
