import 'package:flutter/foundation.dart';

class AppConfig {
  // Define via linha de comando: flutter run --dart-define=API_URL=https://sua-api.onrender.com
  static const String _envUrl = String.fromEnvironment('API_URL');

  static String get defaultBaseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 é o alias do localhost no emulador oficial do Android
      return 'http://10.0.2.2:8080';
    }

    return 'http://localhost:8080';
  }

  // URL padrão sugerida para o Render
  static const String renderProductionUrl = 'https://minha-cantina-api.onrender.com';
}
