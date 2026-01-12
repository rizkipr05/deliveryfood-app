import 'app_services.dart';

class ProductApi {
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
