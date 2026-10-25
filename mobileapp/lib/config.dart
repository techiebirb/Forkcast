import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kReleaseMode;

const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// Run against a local Flask server instead of Render:
/// `flutter run --dart-define=LOCAL_SERVER=true`
const bool _useLocalServer = bool.fromEnvironment('LOCAL_SERVER');

/// The deployed HTTPS server.
const String _prodBaseUrl = 'https://forkcast-8bt8.onrender.com';

bool get isProduction => kReleaseMode;

/// Resolves the Flask base URL.
///
/// Order: `--dart-define=API_BASE_URL=...`, then the local server when
/// `LOCAL_SERVER=true` (debug only), otherwise the deployed server.
/// Android emulator reaches the host machine via 10.0.2.2.
/// iOS simulator / desktop can use 127.0.0.1.
String get apiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _apiBaseUrlOverride;
  }
  if (_useLocalServer && !kReleaseMode) {
    return Platform.isAndroid
        ? 'http://10.0.2.2:8080'
        : 'http://127.0.0.1:8080';
  }
  return _prodBaseUrl;
}
