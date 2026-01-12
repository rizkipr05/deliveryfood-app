import 'app_services.dart';

class PromoApi {
  /// ✅ GET /api/promos
  /// Expected response:
  /// { "data": [ { "id":1, "title":"Diskon 20%", "subtitle":"berlaku...", "color":"#FF8A00" }, ... ] }
  static Future<List<Map<String, dynamic>>> listPromos() async {
    final token = await AppServices.tokenStore.getToken();

    final res = await AppServices.apiClient.get(
      "/api/promos",
      headers: {
        "Accept": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    final data = res["data"];
    if (data is List) {
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return [];
  }

  /// ✅ GET /api/products?promo=1
  /// Expected response:
  /// { "data": [ {id,name,store,price, promo_price, discount_percent, rating, image}, ... ] }
  static Future<List<Map<String, dynamic>>> listPromoProducts({
    String? q,
  }) async {
    final token = await AppServices.tokenStore.getToken();

    final qp = <String, String>{"promo": "1"};
    if (q != null && q.trim().isNotEmpty) qp["q"] = q.trim();

    final path = "/api/products?${Uri(queryParameters: qp).query}";

    final res = await AppServices.apiClient.get(
      path,
      headers: {
        "Accept": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    final data = res["data"];
    if (data is List) {
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return [];
  }
}
