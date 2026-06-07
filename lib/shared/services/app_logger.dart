import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

typedef AppLogSink = void Function(AppLogRecord record);

enum AppLogLevel {
  info,
  warning,
  error,
  fatal,
}

class AppLogRecord {
  const AppLogRecord({
    required this.level,
    required this.message,
    required this.context,
    required this.timestamp,
    this.errorType,
    this.errorMessage,
    this.stackTrace,
  });

  final AppLogLevel level;
  final String message;
  final Map<String, Object?> context;
  final DateTime timestamp;
  final String? errorType;
  final String? errorMessage;
  final StackTrace? stackTrace;

  Map<String, Object?> toJson() {
    return {
      'level': level.name,
      'message': message,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      if (errorType != null) 'error_type': errorType,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }
}

class AppLogger {
  const AppLogger({AppLogSink? sink}) : _sink = sink;

  final AppLogSink? _sink;

  void info(String message, {Map<String, Object?> context = const {}}) {
    _write(_record(AppLogLevel.info, message, context: context));
  }

  void warning(String message, {Map<String, Object?> context = const {}}) {
    _write(_record(AppLogLevel.warning, message, context: context));
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _write(
      _record(
        AppLogLevel.error,
        message,
        error: error,
        stackTrace: stackTrace,
        context: context,
      ),
    );
  }

  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _write(
      _record(
        AppLogLevel.fatal,
        message,
        error: error,
        stackTrace: stackTrace,
        context: context,
      ),
    );
  }

  void flutterError(FlutterErrorDetails details) {
    error(
      details.context?.toDescription() ?? 'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
      context: {
        'library': details.library,
        'silent': details.silent,
      },
    );
  }

  AppLogRecord _record(
    AppLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    return AppLogRecord(
      level: level,
      message: _redactText(message),
      context: sanitizedLogContext(context),
      timestamp: DateTime.now().toUtc(),
      errorType: error?.runtimeType.toString(),
      errorMessage: _redactedErrorMessage(error),
      stackTrace: stackTrace,
    );
  }

  void _write(AppLogRecord record) {
    final sink = _sink;
    if (sink != null) {
      sink(record);
      return;
    }
    developer.log(
      jsonEncode(record.toJson()),
      name: 'fuel_arena',
      level: _developerLevel(record.level),
      error: record.errorMessage,
      stackTrace: record.stackTrace,
    );
  }
}

Map<String, Object?> sanitizedLogContext(Map<String, Object?> context) {
  final sanitized = <String, Object?>{};
  for (final entry in context.entries) {
    if (isSensitiveLogKey(entry.key)) {
      continue;
    }
    sanitized[entry.key] = _sanitizeLogValue(entry.value);
  }
  return sanitized;
}

bool isSensitiveLogKey(String key) {
  final normalized = key.toLowerCase();
  return _sensitiveKeyFragments.any(normalized.contains);
}

Object? _sanitizeLogValue(Object? value) {
  if (value == null || value is num || value is bool) {
    return value;
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is String) {
    return _redactText(value);
  }
  if (value is Map) {
    final sanitized = <String, Object?>{};
    for (final entry in value.entries) {
      final key = '${entry.key}';
      if (isSensitiveLogKey(key)) {
        continue;
      }
      sanitized[key] = _sanitizeLogValue(entry.value);
    }
    return sanitized;
  }
  if (value is Iterable) {
    return value.map(_sanitizeLogValue).toList(growable: false);
  }
  return _redactText(value.toString());
}

String _redactText(String value) {
  var result = value;
  for (final pattern in _sensitiveTextPatterns) {
    result = result.replaceAllMapped(pattern, (match) {
      final prefix = match.group(1) ?? '';
      return '$prefix[redacted]';
    });
  }
  if (result.length <= _maxLogStringLength) {
    return result;
  }
  return '${result.substring(0, _maxLogStringLength)}...';
}

String? _redactedErrorMessage(Object? error) {
  final value = error?.toString();
  return value == null ? null : _redactText(value);
}

int _developerLevel(AppLogLevel level) {
  return switch (level) {
    AppLogLevel.info => 800,
    AppLogLevel.warning => 900,
    AppLogLevel.error => 1000,
    AppLogLevel.fatal => 1200,
  };
}

const _maxLogStringLength = 500;

const _sensitiveKeyFragments = [
  'access_token',
  'anon_key',
  'api_key',
  'authorization',
  'auth_token',
  'drive_points',
  'latitude',
  'location',
  'longitude',
  'password',
  'raw_points',
  'refresh_token',
  'secret',
  'service_role',
  'supabase_key',
  'token',
];

final _sensitiveTextPatterns = [
  RegExp(
    r'\b((?:access_token|anon_key|api_key|authorization|auth_token|password|refresh_token|secret|service_role|supabase_key|token)\s*[:=]\s*)([^,\s}]+)',
    caseSensitive: false,
  ),
];
