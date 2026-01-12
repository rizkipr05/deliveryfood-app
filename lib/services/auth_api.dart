import 'api_client.dart';

class AuthApi {
  final ApiClient client;

  AuthApi(this.client);

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final data = await client.post("/api/auth2/login", body: {
      "email": email,
      "password": password,
    });

    return LoginResult(
      token: data["token"] as String,
      user: Map<String, dynamic>.from(data["user"] as Map),
      message: (data["message"] ?? "").toString(),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await client.post("/api/auth2/register", body: {
      "name": name,
      "email": email,
      "password": password,
    });
  }

  Future<Map<String, dynamic>> me(String token) async {
    final data = await client.get(
      "/api/auth2/me",
      headers: {"Authorization": "Bearer $token"},
    );
    return Map<String, dynamic>.from(data["user"] as Map);
  }

  Future<ForgotPasswordResult> forgotPassword(String email) async {
    final data = await client.post("/api/auth/forgot-password", body: {"email": email});

    // devOtp hanya ada kalau APP_ENV != production
    return ForgotPasswordResult(
      message: (data["message"] ?? "").toString(),
      devOtp: data["devOtp"]?.toString(),
      expiresAt: data["expiresAt"]?.toString(),
    );
  }

  Future<VerifyOtpResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final data = await client.post("/api/auth/verify-otp", body: {
      "email": email,
      "otp": otp,
    });

    return VerifyOtpResult(
      resetToken: data["resetToken"].toString(),
      resetTokenExpiresAt: data["resetTokenExpiresAt"]?.toString(),
      message: (data["message"] ?? "").toString(),
    );
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await client.post("/api/auth/reset-password", body: {
      "resetToken": resetToken,
      "newPassword": newPassword,
      "confirmPassword": confirmPassword,
    });
  }
}

class LoginResult {
  final String token;
  final Map<String, dynamic> user;
  final String message;

  LoginResult({required this.token, required this.user, required this.message});
}

class ForgotPasswordResult {
  final String message;
  final String? devOtp;
  final String? expiresAt;

  ForgotPasswordResult({required this.message, this.devOtp, this.expiresAt});
}

class VerifyOtpResult {
  final String resetToken;
  final String? resetTokenExpiresAt;
  final String message;

  VerifyOtpResult({
    required this.resetToken,
    this.resetTokenExpiresAt,
    required this.message,
  });
}
