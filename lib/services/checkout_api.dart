import 'app_services.dart';

class CheckoutApi {
  static Future<String?> _token() => AppServices.tokenStore.getToken();

  static Future<Map<String, String>> _authHeaders() async {
    final t = await _token();
    if (t == null || t.isEmpty) return {"Accept": "application/json"};
    return {"Accept": "application/json", "Authorization": "Bearer $t"};
  }

  static Future<List<Map<String, dynamic>>> listAddresses() async {
    final headers = await _authHeaders();
    final res = await AppServices.apiClient.get(
      "/api/addresses",
      headers: headers,
    );
    final data = res["data"];
    if (data is List) {
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> checkout({
    required int addressId,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    final headers = await _authHeaders();
    final res = await AppServices.apiClient.post(
      "/api/checkout",
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: {
        "address_id": addressId,
        "note": (note ?? "").trim(),
        "items": items,
      },
    );
    final data = res["data"];
    if (data is Map) return data.cast<String, dynamic>();
    return res.cast<String, dynamic>();
  }

  static Future<void> confirmPayment({
    required int orderId,
    required String method,
  }) async {
    final headers = await _authHeaders();
    await AppServices.apiClient.post(
      "/api/orders/$orderId/confirm-payment",
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: {"method": method},
    );
  }
}
