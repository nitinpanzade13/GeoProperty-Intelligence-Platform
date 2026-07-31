import 'package:flutter/foundation.dart';

class AppLogger {
  static void i(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] [PropertyRadar] $message');
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] [PropertyRadar] $message');
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] [PropertyRadar] $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('Stacktrace: $stackTrace');
    }
  }
}
