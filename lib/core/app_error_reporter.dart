import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'app_environment.dart';
import 'app_logger.dart';

class AppErrorReporter {
  AppErrorReporter._();

  static Future<void> initialize() async {
    final supportedMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (kIsWeb || !supportedMobilePlatform) {
      AppLogger.info('Crashlytics bu platformda pasif bırakıldı.',
          scope: 'error_reporting');
      return;
    }

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(AppEnvironment.crashlyticsEnabled);
  }

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String reason = 'Uygulama hatası',
    bool fatal = false,
    bool printDetails = true,
  }) async {
    if (printDetails) {
      AppLogger.error(
        reason,
        scope: 'error_reporting',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final supportedMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || !supportedMobilePlatform || !AppEnvironment.crashlyticsEnabled) {
      return;
    }

    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
      printDetails: false,
    );
  }

  static Future<void> log(String message, {String scope = 'app'}) async {
    AppLogger.info(message, scope: scope);
    final supportedMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || !supportedMobilePlatform || !AppEnvironment.crashlyticsEnabled) {
      return;
    }
    await FirebaseCrashlytics.instance.log('[$scope] $message');
  }
}
