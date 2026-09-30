import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static const _name = 'DramaByte';

  static void debug(String message, {Map<String, Object?>? data}) {
    if (kDebugMode) {
      _write('DEBUG', message, data: data);
    }
  }

  static void info(String message, {Map<String, Object?>? data}) {
    _write('INFO', message, data: data);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _write('WARNING', message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _write('ERROR', message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    _write('FATAL', message, error: error, stackTrace: stackTrace);
  }

  static void _write(
    String level,
    String message, {
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final safeData = data == null ? '' : ' ${_redact(data)}';
    developer.log(
      '[$level] $message$safeData',
      name: _name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Map<String, Object?> _redact(Map<String, Object?> data) {
    const sensitive = {'token', 'password', 'secret', 'authorization', 'key'};
    return data.map((key, value) {
      final hidden = sensitive.any(key.toLowerCase().contains);
      return MapEntry(key, hidden ? '[REDACTED]' : value);
    });
  }
}
