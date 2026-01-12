import 'app_services.dart';

class ReviewApi {
  static Future<List<Map<String, dynamic>>> listByProduct(int productId) async {
    final res = await AppServices.apiClient.get(
      "/api/ulasan?product_id=$productId",
      headers: {"Accept": "application/json"},
    );
    final data = res["data"];
    if (data is List) {
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return [];
  }

  static Future<void> addReview({
    required int productId,
    required int star,
    required String comment,
  }) async {
    final token = await AppServices.tokenStore.getToken();
    await AppServices.apiClient.post(
      "/api/ulasan",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
      body: {
        "product_id": productId,
        "star": star,
        "comment": comment.trim(),
      },
    );
  }

  static Future<void> updateReview({
    required int reviewId,
    required int star,
    required String comment,
  }) async {
    final token = await AppServices.tokenStore.getToken();
    await AppServices.apiClient.patch(
      "/api/ulasan/$reviewId",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
      body: {
        "star": star,
        "comment": comment.trim(),
      },
    );
  }

  static Future<void> deleteReview({required int reviewId}) async {
    final token = await AppServices.tokenStore.getToken();
    await AppServices.apiClient.delete(
      "/api/ulasan/$reviewId",
      headers: {
        "Accept": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );
  }
}
