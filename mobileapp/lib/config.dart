import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kReleaseMode;

const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// Set this to the deployed HTTPS server before shipping a release build.
const String _prodBaseUrl = 'https://<your-host>';

bool get isProduction => kReleaseMode;

/// Resolves the Flask base URL.
///
/// Order: `--dart-define=API_BASE_URL=...`, then the production URL in
/// release builds, then local development defaults.
/// Android emulator reaches the host machine via 10.0.2.2.
/// iOS simulator / desktop can use 127.0.0.1.
String get apiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _apiBaseUrlOverride;
  }
  if (kReleaseMode) {
    return _prodBaseUrl;
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://127.0.0.1:8080';
}
