import 'package:flutter/material.dart';
import '../../services/cart_api.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const kOrange = Color(0xFFFF8A00);

  bool loading = true;
  List<_CartItem> items = [];

  int get total => items.fold(0, (sum, it) => sum + (it.price * it.qty));

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => loading = true);
    try {
      final rows = await CartApi.listCart();
      if (!mounted) return;
      setState(() {
        items = rows.map(_CartItem.fromMap).toList();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _changeQty(int index, int delta) async {
    final current = items[index];
    final next = current.qty + delta;
    if (next < 1) {
      await _removeItem(index);
      return;
    }

    setState(() {
      items[index] = current.copyWith(qty: next);
    });

    try {
      await CartApi.updateItem(cartId: current.cartId, qty: next);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        items[index] = current;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal update keranjang.")),
      );
    }
  }

  Future<void> _removeItem(int index) async {
    final current = items[index];
    setState(() {
      items.removeAt(index);
    });
    try {
      await CartApi.removeItem(cartId: current.cartId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        items.insert(index, current);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus item.")),
      );
    }
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
          "Keranjang",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCart,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  if (items.isEmpty)
                    _Card(
                      child: Text(
                        "Keranjang masih kosong.",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    )
                  else
                    ...items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return _CartTile(
                        item: item,
                        onMinus: () => _changeQty(i, -1),
                        onPlus: () => _changeQty(i, 1),
                        onRemove: () => _removeItem(i),
                      );
                    }),
                ],
              ),
            ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRupiah(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF3B30),
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: items.isEmpty
                    ? null
                    : () {
                        final first = items.first;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(
                              productId: first.productId,
                              name: first.name,
                              image: first.image,
                              price: first.price,
                              qty: first.qty,
                            ),
                          ),
                        );
                      },
                child: const Text(
                  "Beli Sekarang",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final _CartItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  const _CartTile({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, size: 18),
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
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.8),
                ),
                const SizedBox(height: 2),
                Text(
                  item.store,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.2),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatRupiah(item.price),
                  style: const TextStyle(
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.w900,
                    fontSize: 12.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, size: 16, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 6),
          _QtyBox(qty: item.qty, onMinus: onMinus, onPlus: onPlus),
        ],
      ),
    );
  }
}

class _QtyBox extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniBtn(icon: Icons.remove, onTap: onMinus),
          const SizedBox(width: 8),
          Text(
            "$qty",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
          ),
          const SizedBox(width: 8),
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
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: active ? kOrange.withValues(alpha: 0.12) : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: active ? kOrange : Colors.black87),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const _Card({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
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

class _CartItem {
  final int cartId;
  final int productId;
  final String name;
  final String store;
  final int price;
  final String image;
  final int qty;

  const _CartItem({
    required this.cartId,
    required this.productId,
    required this.name,
    required this.store,
    required this.price,
    required this.image,
    required this.qty,
  });

  _CartItem copyWith({int? qty}) {
    return _CartItem(
      cartId: cartId,
      productId: productId,
      name: name,
      store: store,
      price: price,
      image: image,
      qty: qty ?? this.qty,
    );
  }

  factory _CartItem.fromMap(Map<String, dynamic> m) {
    final img = (m["image"] ?? "").toString().trim();
    final imagePath = img.isEmpty
        ? "lib/assets/produk/burger.png"
        : (img.startsWith("lib/") ? img : "lib/assets/produk/$img");

    return _CartItem(
      cartId: (m["cart_id"] as num).toInt(),
      productId: (m["product_id"] as num).toInt(),
      name: (m["name"] ?? "").toString(),
      store: (m["store"] ?? "").toString(),
      price: ((m["price"] ?? 0) as num).toInt(),
      image: imagePath,
      qty: ((m["qty"] ?? 1) as num).toInt(),
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
