import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/format/uuid.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ViewSender =
    Future<void> Function(String batchId, Map<String, int> items);

final class ViewBatcher {
  ViewBatcher(
    this._send,
    this._preferences, {
    this.interval = const Duration(seconds: 15),
    this.threshold = 25,
    this.maxItems = 50,
    this.maxBackoff = const Duration(minutes: 5),
  }) {
    _restore();
  }

  static const _key = 'view_queue_v1';
  final ViewSender _send;
  final SharedPreferences _preferences;
  final Duration interval;
  final int threshold;
  final int maxItems;
  final Duration maxBackoff;
  final _pending = <String, int>{};
  String? _inflightId;
  Map<String, int> _inflight = {};
  Timer? _timer;
  bool _flushing = false;
  int _failures = 0;

  int get pendingTotal => _pending.values.fold(0, (sum, n) => sum + n);

  void record(String episodeId) {
    _pending[episodeId] = (_pending[episodeId] ?? 0) + 1;
    _persist();
    if (pendingTotal >= threshold) {
      unawaited(flush());
    } else {
      _schedule(interval);
    }
  }

  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    _timer?.cancel();
    try {
      while (_inflightId != null || _pending.isNotEmpty) {
        if (_inflightId == null) _claim();
        try {
          await _send(_inflightId!, _inflight);
        } on DioException catch (error) {
          final status = error.response?.statusCode ?? 0;
          final permanent =
              status >= 400 && status < 500 && status != 429 && status != 401;
          if (!permanent) return _backOff(error);
          AppLogger.warning('View batch dropped', error: error);
        } on Object catch (error) {
          return _backOff(error);
        }
        _inflightId = null;
        _inflight = {};
        _failures = 0;
        _persist();
      }
    } finally {
      _flushing = false;
    }
  }

  void dispose() => _timer?.cancel();

  void _claim() {
    final take = _pending.keys.take(maxItems).toList();
    _inflight = {for (final id in take) id: _pending.remove(id)!};
    _inflightId = generateUuidV4();
    _persist();
  }

  void _backOff(Object error) {
    _failures++;
    final delay = interval * (1 << _failures.clamp(0, 6));
    AppLogger.warning('View batch deferred', error: error);
    _schedule(delay > maxBackoff ? maxBackoff : delay);
  }

  void _schedule(Duration after) {
    if (_timer?.isActive ?? false) return;
    _timer = Timer(after, () => unawaited(flush()));
  }

  void _persist() {
    unawaited(
      _preferences.setString(
        _key,
        jsonEncode({
          'pending': _pending,
          'inflight': _inflightId == null
              ? null
              : {'id': _inflightId, 'items': _inflight},
        }),
      ),
    );
  }

  void _restore() {
    final raw = _preferences.getString(_key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _pending.addAll(_counts(data['pending']));
      final inflight = data['inflight'];
      if (inflight is Map<String, dynamic> && inflight['id'] is String) {
        _inflightId = inflight['id'] as String;
        _inflight = _counts(inflight['items']);
      }
    } on Object {
      _pending.clear();
    }
    if (_inflightId != null || _pending.isNotEmpty) _schedule(interval);
  }

  Map<String, int> _counts(Object? raw) => {
    if (raw is Map)
      for (final entry in raw.entries)
        if (entry.key is String &&
            entry.value is int &&
            (entry.value as int) > 0)
          entry.key as String: entry.value as int,
  };
}
