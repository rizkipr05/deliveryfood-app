import '../../services/app_services.dart';
import '../../services/api_client.dart';

class ProfileApi {
  // helper ambil token
  static Future<String?> _token() => AppServices.tokenStore.getToken();

  // helper headers auth
  static Future<Map<String, String>> _authHeaders() async {
    final t = await _token();
    if (t == null || t.isEmpty) return {"Accept": "application/json"};
    return {"Accept": "application/json", "Authorization": "Bearer $t"};
  }

  // ===== USER =====
  static Future<Map<String, dynamic>> me() async {
    final t = await _token();
    if (t == null || t.isEmpty) {
      throw ApiException("Unauthorized", statusCode: 401);
    }
    // Gunakan endpoint auth2/me yang memang tersedia di backend saat ini.
    return await AppServices.authApi.me(t);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
  }) async {
    final headers = await _authHeaders();
    
    return await AppServices.apiClient.put(
      "/api/users/me",
      body: {"name": name, "phone": phone},
      headers: headers,
    );
  }

  // ===== ADDRESSES =====
  static Future<List<Map<String, dynamic>>> listAddresses() async {
    final headers = await _authHeaders();
    final res = await AppServices.apiClient.get(
      "/api/addresses",
      headers: headers,
    );
    final data = (res["data"] as List).cast<dynamic>();
    return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  static Future<void> addAddress({
    required String title,
    required String detail,
    bool isPrimary = false,
  }) async {
    final headers = await _authHeaders();
    await AppServices.apiClient.post(
      "/api/addresses",
      body: {"title": title, "detail": detail, "is_primary": isPrimary},
      headers: headers,
    );
  }

  // ===== PASSWORD =====
  static Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final headers = await _authHeaders();
    await AppServices.apiClient.put(
      "/api/auth/change-password",
      body: {
        "email": email,
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      },
      headers: headers,
    );
  }

  // ===== OTP =====
  static Future<void> requestOtp({required String email}) async {
    await AppServices.apiClient.post(
      "/api/auth/request-otp",
      body: {"email": email},
    );
  }

  static Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await AppServices.apiClient.post(
      "/api/auth/verify-otp",
      body: {"email": email, "otp": otp},
    );
  }
}
