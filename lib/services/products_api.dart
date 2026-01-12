import 'api_client.dart';

class ProductsApi {
  final ApiClient client;
  ProductsApi(this.client);

  Future<List<Product>> list({String? category, String? q}) async {
    final query = <String, String>{};
    if (category != null && category.isNotEmpty) query["category"] = category;
    if (q != null && q.isNotEmpty) query["q"] = q;

    final path = query.isEmpty
        ? "/api/products"
        : "/api/products?${Uri(queryParameters: query).query}";

    final data = await client.get(path);
    final list = (data["data"] as List).cast<Map<String, dynamic>>();
    return list.map((e) => Product.fromJson(e)).toList();
  }
}

class Product {
  final int id;
  final String name;
  final String category;
  final String store;
  final int price;
  final double rating;
  final String? image; // "food_1.jpg"

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.store,
    required this.price,
    required this.rating,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json["id"] as num).toInt(),
      name: (json["name"] ?? "").toString(),
      category: (json["category"] ?? "Semua").toString(),
      store: (json["store"] ?? "").toString(),
      price: (json["price"] as num).toInt(),
      rating: (json["rating"] as num).toDouble(),
      image: json["image"]?.toString(),
    );
  }
}
