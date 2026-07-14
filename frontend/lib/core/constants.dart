import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'ACA Portal';

  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api'; // Android emulator local address
      }
    } catch (_) {}
    return 'http://127.0.0.1:3000/api'; // iOS / macOS / Windows / Linux localhost
  }

  static const String tokenKey = 'auth_token';
  static const String userEmailKey = 'user_email';
}
