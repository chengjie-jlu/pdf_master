import 'package:flutter/foundation.dart';

const _brand = "PDFMaster";

enum LogLevel {
  debug('D', '\x1B[90m', 500),
  info('I', '\x1B[34m', 800),
  warning('W', '\x1B[33m', 900),
  error('E', '\x1B[31m', 1000);

  const LogLevel(this.label, this.color, this.value);

  final String label;
  final String color;
  final int value;
}

class Log {
  Log._();

  // ANSI 重置代码
  static const String _reset = '\x1B[0m';

  static void _log(LogLevel level, String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final formattedMessage = "${level.color}${level.label}/[$_brand-$tag]: $message$_reset";

    debugPrint(formattedMessage);
    if (error != null) {
      debugPrint("${level.color}  Error: $error$_reset");
    }
    if (stackTrace != null) {
      debugPrint("${level.color}  StackTrace: $stackTrace$_reset");
    }
  }

  static void d(String tag, String message) {
    if (kDebugMode) {
      _log(LogLevel.debug, tag, message);
    }
  }

  static void i(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  static void w(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, tag, message, error, stackTrace);
  }

  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message, error, stackTrace);
  }
}
