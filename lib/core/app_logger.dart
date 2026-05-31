import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message, {String scope = 'app'}) {
    debugPrint('[INFO][$scope] $message');
  }

  static void warning(String message, {String scope = 'app'}) {
    debugPrint('[WARN][$scope] $message');
  }

  static void error(
    String message, {
    String scope = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('[ERROR][$scope] $message');
    if (error != null) {
      debugPrint('[ERROR][$scope] cause=$error');
    }
    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }
  }
}
