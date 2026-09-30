abstract final class AppLinks {
  static const scheme = 'dramabyte';
  static const host = 'app';
  static const nextParam = 'next';

  static String seriesPath(String seriesId) => '/series/$seriesId';

  static Uri seriesUri(String seriesId) =>
      Uri(scheme: scheme, host: host, path: seriesPath(seriesId));

  static String? safeNext(String? next) {
    if (next == null || !next.startsWith('/')) return null;
    if (next.startsWith('//') || next.contains('://')) return null;
    return next;
  }
}
