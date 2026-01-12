import 'package:flutter/material.dart';
import '../../services/products_api.dart';
import 'checkout_page.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final Map<String, dynamic>? initialData;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.initialData,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  static const kOrange = Color(0xFFFF8A00);

  bool loading = true;
  Map<String, dynamic>? data;

  int qty = 1;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      data = Map<String, dynamic>.from(widget.initialData!);
      loading = false;
    }
    if (widget.productId > 0) {
      _load();
    } else {
      loading = false;
    }
  }

  Future<void> _load() async {
    if (data == null) setState(() => loading = true);
    try {
      final res = await ProductApi.detail(widget.productId);
      if (!mounted) return;
      setState(() {
        data = res;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  String _assetFromBackend(String file, {String fallback = "lib/assets/6.png"}) {
    final f = file.trim();
    if (f.isEmpty) return fallback;
    if (f.startsWith("lib/")) return f;
    return "lib/assets/produk/$f";
  }

  @override
  Widget build(BuildContext context) {
    final m = data ?? {};
    final name = (m["name"] ?? "Burger Spesial").toString();
    final store = (m["store"] ?? "Warung").toString();
    final desc = (m["description"] ??
            "Menu ini dibuat dengan bahan pilihan, fresh, dan cocok untuk menemani aktivitas kamu.")
        .toString();

    final price = ((m["price"] ?? 25000) as num).toInt();
    final rating = ((m["rating"] ?? 4.9) as num).toDouble();
    final image = _assetFromBackend((m["image"] ?? "").toString(), fallback: "lib/assets/6.png");

    final reviewsRaw = (m["reviews"] is List) ? (m["reviews"] as List) : [];
    final reviews = reviewsRaw
        .map((e) => (e as Map).cast<String, dynamic>())
        .map(_Review.fromMap)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // HERO IMAGE
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.05,
                          child: Image.asset(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.image_not_supported)),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 12,
                          child: _IconCircle(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 12,
                          child: _IconCircle(
                            icon: Icons.favorite_border,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),

                    // CONTENT
                    Container(
                      transform: Matrix4.translationValues(0, -18, 0),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // title + qty
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      store,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _QtyBox(
                                qty: qty,
                                onMinus: () => setState(() {
                                  if (qty > 1) qty--;
                                }),
                                onPlus: () => setState(() => qty++),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Text(
                                _formatRupiah(price),
                                style: const TextStyle(
                                  color: Color(0xFFFF3B30),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB300)),
                              const SizedBox(width: 4),
                              Text(
                                "${rating.toStringAsFixed(1)} / 5.0",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            "Detail Menu",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          _Card(
                            child: Text(
                              desc,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                height: 1.35,
                                fontSize: 12.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Rating box (mirip screenshot)
                          _Card(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Rating",
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: kOrange,
                                        ),
                                      ),
                                      Text(
                                        "Berdasarkan ulasan",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    children: List.generate(5, (i) {
                                      final star = 5 - i;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          children: [
                                            Text(
                                              "$star",
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: _fakeProgress(star, rating),
                                                  minHeight: 6,
                                                  backgroundColor: const Color(0xFFF0F0F0),
                                                  valueColor: const AlwaysStoppedAnimation(kOrange),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            "Ulasan",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          const SizedBox(height: 10),

                          if (reviews.isEmpty)
                            _Card(
                              child: Text(
                                "Belum ada ulasan dari backend.",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            )
                          else
                            ...reviews.map((r) => _ReviewTile(r: r)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),

      // Bottom button seperti gambar
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: loading
                      ? null
                      : () async {
                          // 1) masukin cart (backend)
                          try {
                            await ProductApi.addToCart(productId: widget.productId, qty: qty);
                          } catch (_) {
                            // kalau endpoint cart belum ada, tetap lanjut ke checkout (optional)
                          }

                          if (!context.mounted) return;

                          // 2) buka checkout
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutPage(
                                productId: widget.productId,
                                name: name,
                                image: image,
                                price: price,
                                qty: qty,
                              ),
                            ),
                          );
                        },
                  child: const Text(
                    "Pesan Sekarang",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== widgets ======

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }
}

class _QtyBox extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _QtyBox({required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniBtn(icon: Icons.remove, onTap: onMinus),
          const SizedBox(width: 10),
          Text(
            "$qty",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(width: 10),
          _MiniBtn(icon: Icons.add, onTap: onPlus, active: true),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _MiniBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active ? kOrange.withValues(alpha: 0.12) : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: active ? kOrange : Colors.black87),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: child,
    );
  }
}

class _Review {
  final String name;
  final int star;
  final String comment;

  _Review({required this.name, required this.star, required this.comment});

  factory _Review.fromMap(Map<String, dynamic> m) {
    return _Review(
      name: (m["name"] ?? "User").toString(),
      star: ((m["star"] ?? 5) as num).toInt(),
      comment: (m["comment"] ?? "").toString(),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final _Review r;
  const _ReviewTile({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: i < r.star ? const Color(0xFFFFB300) : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.comment.isEmpty ? "Mantap dan enak!" : r.comment,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12.2, height: 1.3),
          ),
        ],
      ),
    );
  }
}

double _fakeProgress(int star, double rating) {
  // biar bar rating keliatan bagus walau backend belum kirim distribusi
  final base = rating / 5.0;
  if (star == 5) return (base + 0.25).clamp(0.0, 1.0);
  if (star == 4) return (base + 0.05).clamp(0.0, 1.0);
  if (star == 3) return (base - 0.10).clamp(0.0, 1.0);
  if (star == 2) return (base - 0.20).clamp(0.0, 1.0);
  return (base - 0.28).clamp(0.0, 1.0);
}

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
