import 'package:flutter/material.dart';
import '../../services/order_api.dart';
import '../homes/product_detail_page.dart';
import '../homes/payment_success_page.dart';
import 'review_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool loading = true;
  bool showHistory = true;
  List<_OrderItem> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final status = showHistory ? "history" : "processing";
      final rows = await OrderApi.listOrders(status: status);
      if (!mounted) return;
      setState(() {
        items = rows.map(_OrderItem.fromMap).toList();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _cancelOrder(_OrderItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF2E8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFF8A00), size: 28),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Apakah Anda Yakin Ingin batalkan pesanan ini?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Batal"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Ya Batalkan"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (ok != true) return;

    try {
      await OrderApi.cancelOrder(orderId: item.orderId);
      if (!mounted) return;
      _showMiniPopup("Pesanan Berhasil Dibatalkan");
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membatalkan pesanan.")),
      );
    }
  }

  void _showMiniPopup(String text) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFA200), Color(0xFFFF3B30)],
                      ),
                    ),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Aktifitas",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TabItem(
                  label: "Riwayat",
                  active: showHistory,
                  onTap: () {
                    if (!showHistory) {
                      setState(() => showHistory = true);
                      _load();
                    }
                  },
                ),
                const SizedBox(width: 16),
                _TabItem(
                  label: "Dalam Proses",
                  active: !showHistory,
                  onTap: () {
                    if (showHistory) {
                      setState(() => showHistory = false);
                      _load();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return _OrderCard(
                          item: item,
                          showHistory: showHistory,
                          onReview: () async {
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewPage(
                                  productId: item.productId,
                                  productName: item.name,
                                ),
                              ),
                            );
                            if (ok == true) {
                              _showMiniPopup("Ulasan Berhasil Terkirim");
                              _load();
                            }
                          },
                          onOrderAgain: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(
                                  productId: item.productId,
                                  initialData: {
                                    "id": item.productId,
                                    "name": item.name,
                                    "store": item.store,
                                    "price": item.total,
                                    "rating": 4.9,
                                    "image": item.image,
                                  },
                                ),
                              ),
                            );
                          },
                          onSeeOrder: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentSuccessPage(
                                  orderId: item.orderId,
                                  total: item.total,
                                  method: item.paymentMethod,
                                  deliveryMethod: item.deliveryMethod,
                                ),
                              ),
                            );
                          },
                          onCancel: () => _cancelOrder(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFFFF8A00) : Colors.grey.shade600,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 46,
            height: 2,
            color: active ? const Color(0xFFFF8A00) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _OrderItem item;
  final bool showHistory;
  final VoidCallback onReview;
  final VoidCallback onOrderAgain;
  final VoidCallback onSeeOrder;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.item,
    required this.showHistory,
    required this.onReview,
    required this.onOrderAgain,
    required this.onSeeOrder,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.image,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRupiah(item.total),
                      style: const TextStyle(
                        color: Color(0xFFFF3B30),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Metode Pembayaran",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            item.paymentMethod.toUpperCase().replaceAll("_", " "),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (showHistory)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOrderAgain,
                    child: const Text("Pesan Lagi"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: item.reviewStar > 0
                      ? _StarRow(star: item.reviewStar)
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: onReview,
                          child: const Text("Beri Ulasan"),
                        ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSeeOrder,
                    child: const Text("Nomor Pesanan"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onCancel,
                    child: const Text("Batalkan Pesanan"),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int star;
  const _StarRow({required this.star});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => Icon(
          Icons.star_rounded,
          size: 16,
          color: i < star ? const Color(0xFFFFB300) : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }
}

class _OrderItem {
  final int orderId;
  final int productId;
  final String name;
  final String store;
  final String image;
  final int total;
  final int qty;
  final String paymentMethod;
  final String deliveryMethod;
  final int reviewStar;

  _OrderItem({
    required this.orderId,
    required this.productId,
    required this.name,
    required this.store,
    required this.image,
    required this.total,
    required this.qty,
    required this.paymentMethod,
    required this.deliveryMethod,
    required this.reviewStar,
  });

  factory _OrderItem.fromMap(Map<String, dynamic> m) {
    final img = (m["image"] ?? "").toString().trim();
    final imagePath = img.isEmpty
        ? "lib/assets/produk/burger.png"
        : (img.startsWith("lib/") ? img : "lib/assets/produk/$img");

    return _OrderItem(
      orderId: (m["id"] as num).toInt(),
      productId: (m["product_id"] as num).toInt(),
      name: (m["name"] ?? "").toString(),
      store: (m["store"] ?? "").toString(),
      image: imagePath,
      total: ((m["total"] ?? 0) as num).toInt(),
      qty: ((m["qty"] ?? 1) as num).toInt(),
      paymentMethod: (m["payment_method"] ?? "qris").toString(),
      deliveryMethod: (m["delivery_method"] ?? "pickup").toString(),
      reviewStar: ((m["review_star"] ?? 0) as num).toInt(),
    );
  }
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
