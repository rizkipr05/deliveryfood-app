import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/promo_api.dart';

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  bool loading = true;
  bool loadingProducts = true;

  List<_PromoBannerItem> promoBanners = [];
  List<_PromoProduct> products = [];

  final searchC = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchC.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      loading = true;
      loadingProducts = true;
    });

    try {
      final promosRaw = await PromoApi.listPromos();
      final mappedPromos = promosRaw
          .map((m) => _PromoBannerItem.fromMap(m))
          .toList();

      if (!mounted) return;
      setState(() {
        promoBanners = mappedPromos.isEmpty
            ? const [
                _PromoBannerItem(
                  title: "Diskon\n20%",
                  subtitle: "berlaku\nhari ini",
                  color: Color(0xFFFF8A00),
                ),
                _PromoBannerItem(
                  title: "Diskon\n10%",
                  subtitle: "untuk\nsemua",
                  color: Color(0xFF1DB954),
                ),
              ]
            : mappedPromos;
        loading = false;
      });

      await _loadProducts();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadingProducts = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() => loadingProducts = true);
    try {
      final raw = await PromoApi.listPromoProducts(q: searchC.text.trim());

      final mapped = raw.map((m) => _PromoProduct.fromMap(m)).toList();

      if (!mounted) return;
      setState(() {
        products = mapped;
        loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingProducts = false);
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAll,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: [
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        "Promo",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search (opsional, biar bisa filter produk promo)
                    _SearchBar(
                      controller: searchC,
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 14),

                    const _SectionTitle("Promo Berlaku"),
                    const SizedBox(height: 10),

                    _PromoStrip(items: promoBanners, onTap: (_) {}),

                    const SizedBox(height: 16),
                    const _SectionTitle("Promo Berlaku"),
                    const SizedBox(height: 10),

                    loadingProducts
                        ? const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                            itemBuilder: (_, i) =>
                                _PromoProductCard(p: products[i], onTap: () {}),
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}

// =========================
// UI Components
// =========================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: Colors.black,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Cari promo...",
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.orange.shade300, width: 1.2),
        ),
      ),
    );
  }
}

class _PromoStrip extends StatelessWidget {
  final List<_PromoBannerItem> items;
  final ValueChanged<_PromoBannerItem> onTap;

  const _PromoStrip({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final it = items[i];
          return InkWell(
            onTap: () => onTap(it),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: it.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      it.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    it.subtitle,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PromoProductCard extends StatelessWidget {
  final _PromoProduct p;
  final VoidCallback onTap;
  static const kOrange = Color(0xFFFF8A00);

  const _PromoProductCard({required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Image.asset(
                    p.image,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${p.discountPercent}% off",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.store,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFFB300),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // price
                  Row(
                    children: [
                      Text(
                        _formatRupiah(p.oldPrice),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10.5,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatRupiah(p.price),
                        style: const TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// Models
// =========================

class _PromoBannerItem {
  final String title;
  final String subtitle;
  final Color color;

  const _PromoBannerItem({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  factory _PromoBannerItem.fromMap(Map<String, dynamic> m) {
    final title = (m["title"] ?? "Diskon").toString();
    final subtitle = (m["subtitle"] ?? "").toString();

    // support color hex string dari backend, contoh "#FF8A00"
    final c = (m["color"] ?? "").toString().trim();
    final color = _parseHexColor(c) ?? const Color(0xFFFF8A00);

    return _PromoBannerItem(title: title, subtitle: subtitle, color: color);
  }
}

class _PromoProduct {
  final String name;
  final String store;
  final int oldPrice;
  final int price;
  final int discountPercent;
  final double rating;
  final String image;

  const _PromoProduct({
    required this.name,
    required this.store,
    required this.oldPrice,
    required this.price,
    required this.discountPercent,
    required this.rating,
    required this.image,
  });

  factory _PromoProduct.fromMap(Map<String, dynamic> m) {
    final name = (m["name"] ?? "").toString();
    final store = (m["store"] ?? "").toString();

    final price = ((m["promo_price"] ?? m["price"] ?? 0) as num).toInt();
    final oldPrice = ((m["price"] ?? price) as num).toInt();

    final dp = (m["discount_percent"] ?? 0);
    final discountPercent = (dp is num) ? dp.toInt() : 0;

    final rating = ((m["rating"] ?? 4.9) as num).toDouble();

    // image dari backend: "burger.png" => assets/produk/burger.png
    final img = (m["image"] ?? "").toString().trim();
    final imagePath = img.isEmpty
        ? "lib/assets/produk/burger.png"
        : "lib/assets/produk/$img";

    return _PromoProduct(
      name: name,
      store: store,
      oldPrice: oldPrice,
      price: price,
      discountPercent: discountPercent == 0
          ? _calcDiscount(oldPrice, price)
          : discountPercent,
      rating: rating,
      image: imagePath,
    );
  }

  static int _calcDiscount(int oldPrice, int newPrice) {
    if (oldPrice <= 0) return 0;
    final diff = oldPrice - newPrice;
    if (diff <= 0) return 0;
    final pct = (diff * 100) / oldPrice;
    return pct.round();
  }
}

// =========================
// Utils
// =========================

String _formatRupiah(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(".");
  }
  return "Rp ${buf.toString()}";
}

Color? _parseHexColor(String hex) {
  if (hex.isEmpty) return null;
  var h = hex.replaceAll("#", "").toUpperCase();
  if (h.length == 6) h = "FF$h";
  if (h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  if (v == null) return null;
  return Color(v);
}
