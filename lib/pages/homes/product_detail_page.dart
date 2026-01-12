import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../services/products_api.dart';
import '../../services/review_api.dart';
import 'checkout_page.dart';
import 'cart_page.dart';

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
  bool loadingReviews = true;
  List<_Review> reviews = [];
  int? currentUserId;

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
      _loadReviews();
      _loadCurrentUser();
    } else {
      loading = false;
      loadingReviews = false;
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

  Future<void> _loadReviews() async {
    setState(() => loadingReviews = true);
    try {
      final raw = await ReviewApi.listByProduct(widget.productId);
      final list = raw.map(_Review.fromMap).toList();
      if (!mounted) return;
      setState(() {
        reviews = list;
        loadingReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingReviews = false);
    }
  }

  Future<void> _loadCurrentUser() async {
    final token = await AppServices.tokenStore.getToken();
    if (token == null || token.isEmpty) return;
    try {
      final user = await AppServices.authApi.me(token);
      if (!mounted) return;
      setState(() {
        currentUserId = (user["id"] as num?)?.toInt();
      });
    } catch (_) {}
  }

  Future<void> _showAddReviewDialog() async {
    final commentC = TextEditingController();
    int star = 5;
    try {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                title: const Text("Tambah Ulasan"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final active = i < star;
                        return IconButton(
                          onPressed: () => setLocal(() => star = i + 1),
                          icon: Icon(
                            active ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFFFB300),
                          ),
                        );
                      }),
                    ),
                    TextField(
                      controller: commentC,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Tulis ulasan kamu...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Batal"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Kirim"),
                  ),
                ],
              );
            },
          );
        },
      );

      if (ok != true) return;

      await ReviewApi.addReview(
        productId: widget.productId,
        star: star,
        comment: commentC.text,
      );
      if (!mounted) return;
      await _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ulasan berhasil ditambahkan.")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menambahkan ulasan.")),
      );
    } finally {
      commentC.dispose();
    }
  }

  Future<void> _showEditReviewDialog(_Review review) async {
    final commentC = TextEditingController(text: review.comment);
    int star = review.star;
    try {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                title: const Text("Edit Ulasan"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final active = i < star;
                        return IconButton(
                          onPressed: () => setLocal(() => star = i + 1),
                          icon: Icon(
                            active ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFFFB300),
                          ),
                        );
                      }),
                    ),
                    TextField(
                      controller: commentC,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Tulis ulasan kamu...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Batal"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Simpan"),
                  ),
                ],
              );
            },
          );
        },
      );

      if (ok != true) return;

      await ReviewApi.updateReview(
        reviewId: review.id,
        star: star,
        comment: commentC.text,
      );
      if (!mounted) return;
      await _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ulasan diperbarui.")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memperbarui ulasan.")),
      );
    } finally {
      commentC.dispose();
    }
  }

  Future<void> _deleteReview(_Review review) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Hapus Ulasan?"),
          content: const Text("Ulasan ini akan dihapus permanen."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await ReviewApi.deleteReview(reviewId: review.id);
      if (!mounted) return;
      await _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ulasan dihapus.")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus ulasan.")),
      );
    }
  }

  String _assetFromBackend(String file, {String fallback = "lib/assets/6.png"}) {
    final f = file.trim();
    if (f.isEmpty) return fallback;
    if (f.startsWith("lib/")) return f;
    return "lib/assets/produk/$f";
  }

  void _showCartAddedToast() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFA200), Color(0xFFFF3B30)],
                      ),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Ditambahkan Ke Keranjang",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
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

    final reviewsList = reviews;

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

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Ulasan",
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                              ),
                              TextButton(
                                onPressed: loadingReviews ? null : _showAddReviewDialog,
                                child: const Text("Tambah"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (loadingReviews)
                            const _Card(
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (reviewsList.isEmpty)
                            _Card(
                              child: Text(
                                "Belum ada ulasan dari backend.",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            )
                          else
                            ...reviewsList.map(
                              (r) => _ReviewTile(
                                r: r,
                                isOwner: currentUserId != null && r.userId == currentUserId,
                                onEdit: () => _showEditReviewDialog(r),
                                onDelete: () => _deleteReview(r),
                              ),
                            ),
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
              InkWell(
                onTap: loading
                    ? null
                    : () async {
                        try {
                          await ProductApi.addToCart(productId: widget.productId, qty: qty);
                          if (!context.mounted) return;
                          _showCartAddedToast();
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Gagal menambahkan ke keranjang.")),
                          );
                        }
                      },
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined, color: kOrange),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA200), Color(0xFFFF3B30)],
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: loading
                          ? null
                          : () async {
                              try {
                                await ProductApi.addToCart(
                                  productId: widget.productId,
                                  qty: qty,
                                );
                              } catch (_) {}

                              if (!context.mounted) return;

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
                        "Pesan & Bayar Sekarang",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
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
  final int id;
  final int userId;
  final String name;
  final int star;
  final String comment;
  final String createdAt;

  _Review({
    required this.id,
    required this.userId,
    required this.name,
    required this.star,
    required this.comment,
    required this.createdAt,
  });

  factory _Review.fromMap(Map<String, dynamic> m) {
    return _Review(
      id: ((m["id"] ?? 0) as num).toInt(),
      userId: ((m["user_id"] ?? 0) as num).toInt(),
      name: (m["name"] ?? "User").toString(),
      star: ((m["star"] ?? 5) as num).toInt(),
      comment: (m["comment"] ?? "").toString(),
      createdAt: (m["created_at"] ?? "").toString(),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final _Review r;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewTile({
    required this.r,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    r.name.isEmpty ? "U" : r.name[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == "edit") onEdit();
                    if (v == "delete") onDelete();
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: "edit", child: Text("Edit")),
                    PopupMenuItem(value: "delete", child: Text("Hapus")),
                  ],
                  icon: const Icon(Icons.more_vert, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.comment.isEmpty ? "Mantap dan enak!" : r.comment,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12.2, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            _timeAgo(r.createdAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(String iso) {
  if (iso.isEmpty) return "";
  DateTime? dt;
  try {
    dt = DateTime.parse(iso);
  } catch (_) {
    return iso;
  }
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return "Baru saja";
  if (diff.inMinutes < 60) return "${diff.inMinutes} Menit Lalu";
  if (diff.inHours < 24) return "${diff.inHours} Jam Lalu";
  if (diff.inDays < 7) return "${diff.inDays} Hari Lalu";
  if (diff.inDays < 30) return "${(diff.inDays / 7).floor()} Minggu Lalu";
  if (diff.inDays < 365) return "${(diff.inDays / 30).floor()} Bulan Lalu";
  return "${(diff.inDays / 365).floor()} Tahun Lalu";
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
