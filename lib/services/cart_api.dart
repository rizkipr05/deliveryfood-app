import 'app_services.dart';

class CartApi {
  static Future<String?> _token() => AppServices.tokenStore.getToken();

  static Future<Map<String, String>> _authHeaders() async {
    final t = await _token();
    if (t == null || t.isEmpty) return {"Accept": "application/json"};
    return {"Accept": "application/json", "Authorization": "Bearer $t"};
  }

  static Future<List<Map<String, dynamic>>> listCart() async {
    final headers = await _authHeaders();
    final res = await AppServices.apiClient.get("/api/cart", headers: headers);
    final data = res["data"];
    if (data is List) {
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return [];
  }

  static Future<void> updateItem({
    required int cartId,
    required int qty,
  }) async {
    final headers = await _authHeaders();
    await AppServices.apiClient.patch(
      "/api/cart/item/$cartId",
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: {"qty": qty},
    );
  }

  static Future<void> removeItem({required int cartId}) async {
    final headers = await _authHeaders();
    await AppServices.apiClient.delete(
      "/api/cart/item/$cartId",
      headers: headers,
    );
  }
}
