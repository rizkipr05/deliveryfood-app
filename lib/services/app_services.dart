import 'package:flutter/foundation.dart';
import 'package:flutter_app/services/api_client.dart';
import 'package:flutter_app/services/auth_api.dart';
import 'package:flutter_app/services/token_store.dart';

class AppServices {
  // Android Emulator: http://10.0.2.2:3001
  // Physical device: http://<PC_IP>:3001 (set via --dart-define)
  // Web/iOS/Desktop: http://localhost:3001
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kIsWeb) return "http://localhost:3001";
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://10.0.2.2:3001";
      default:
        return "http://localhost:3001";
    }
  }

  static final apiClient = ApiClient(baseUrl: baseUrl);
  static final authApi = AuthApi(apiClient);
  static final tokenStore = TokenStore();
}
