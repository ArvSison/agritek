import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// API base URL (no trailing slash).
///
/// Override at build/run time: `--dart-define=API_BASE=http://192.168.1.5/agritek_api`
///
/// - Android emulator: `10.0.2.2` reaches the host machine’s localhost.
/// - Physical device: use your PC’s LAN IP via [API_BASE].
class ApiConfig {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    // Production default (release builds) when no --dart-define is provided.
    // Keep this in sync with your deployed Hostinger API base.
    if (kReleaseMode) return 'https://api.agritechph.org/agritek_api';

    // For Web, `localhost` maps to your Apache DocumentRoot.
    // If your DocumentRoot is `C:\xampp\htdocs\LibraryMonitoring\`, then your API is:
    //   http://localhost/agritek_api
    // If your DocumentRoot is `C:\xampp\htdocs\`, then use:
    //   --dart-define=API_BASE=http://localhost/LibraryMonitoring/agritek_api
    if (kIsWeb) return 'http://localhost/agritek_api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2/agritek_api';
    } catch (_) {}
    return 'http://localhost/agritek_api';
  }
}

