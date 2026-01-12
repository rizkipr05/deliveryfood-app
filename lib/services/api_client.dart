import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse("$baseUrl$path");

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              ...?headers,
            },
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw ApiException("Request timeout");
    }

    final text = res.body.isEmpty ? "{}" : res.body;
    final data = jsonDecode(text);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    final msg = (data is Map && (data["message"] != null))
        ? data["message"].toString()
        : "Request gagal (${res.statusCode})";
    throw ApiException(msg, statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse("$baseUrl$path");

    http.Response res;
    try {
      res = await http
          .get(
            uri,
            headers: {
              "Accept": "application/json",
              ...?headers,
            },
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw ApiException("Request timeout");
    }

    final text = res.body.isEmpty ? "{}" : res.body;
    final data = jsonDecode(text);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    final msg = (data is Map && (data["message"] != null))
        ? data["message"].toString()
        : "Request gagal (${res.statusCode})";
    throw ApiException(msg, statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse("$baseUrl$path");

    http.Response res;
    try {
      res = await http
          .put(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              ...?headers,
            },
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw ApiException("Request timeout");
    }

    final text = res.body.isEmpty ? "{}" : res.body;
    final data = jsonDecode(text);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    final msg = (data is Map && (data["message"] != null))
        ? data["message"].toString()
        : "Request gagal (${res.statusCode})";
    throw ApiException(msg, statusCode: res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
