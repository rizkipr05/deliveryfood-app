import 'app_services.dart';

class ProductApi {
  static Future<List<Map<String, dynamic>>> listProducts({
    String? category,
    String? q,
    bool promoOnly = false,
  }) async {
    final token = await AppServices.tokenStore.getToken();

    final qp = <String, String>{};
    if (category != null && category.trim().isNotEmpty) qp["category"] = category.trim();
    if (q != null && q.trim().isNotEmpty) qp["q"] = q.trim();
    if (promoOnly) qp["promo"] = "1";

    final path = qp.isEmpty
        ? "/api/products"
        : "/api/products?${Uri(queryParameters: qp).query}";

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

  static Future<Map<String, dynamic>> detail(int id) async {
    final token = await AppServices.tokenStore.getToken();

    final res = await AppServices.apiClient.get(
      "/api/products/$id",
      headers: {
        "Accept": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    final data = res["data"];
    if (data is Map) return data.cast<String, dynamic>();
    return {};
  }

  static Future<void> addToCart({
    required int productId,
    required int qty,
  }) async {
    final token = await AppServices.tokenStore.getToken();

    await AppServices.apiClient.post(
      "/api/cart/add",
      body: {"product_id": productId, "qty": qty},
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );
  }
}
