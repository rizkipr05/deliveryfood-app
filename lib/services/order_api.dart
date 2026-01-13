import 'app_services.dart';

class OrderApi {
  static Future<String?> _token() => AppServices.tokenStore.getToken();

  static Future<Map<String, String>> _authHeaders() async {
    final t = await _token();
    if (t == null || t.isEmpty) return {"Accept": "application/json"};
    return {"Accept": "application/json", "Authorization": "Bearer $t"};
  }

  static Future<List<Map<String, dynamic>>> listOrders({
    required String status,
  }) async {
    final headers = await _authHeaders();
    final res = await AppServices.apiClient.get(
      "/api/orders?status=$status",
      headers: headers,
    );
    final data = res["data"];
    if (data is List) {
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return [];
  }

  static Future<void> cancelOrder({required int orderId}) async {
    final headers = await _authHeaders();
    await AppServices.apiClient.post(
      "/api/orders/$orderId/cancel",
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: {},
    );
  }
}
