import 'package:flutter/material.dart';
import '../../services/checkout_api.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  final int productId;
  final String name;
  final String image;
  final int price;
  final int qty;

  const CheckoutPage({
    super.key,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.qty,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const kOrange = Color(0xFFFF8A00);

  bool loading = true;
  List<Map<String, dynamic>> addresses = [];
  int? selectedAddressId;
  String deliveryMethod = "pickup";
  late int qty;

  final noteC = TextEditingController();

  int get subtotal => widget.price * qty;
  int get deliveryFee => deliveryMethod == "delivery" ? 5000 : 0;
  int get total => subtotal + deliveryFee;

  @override
  void initState() {
    super.initState();
    qty = widget.qty;
    _loadAddresses();
  }

  @override
  void dispose() {
    noteC.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => loading = true);
    try {
      final list = await CheckoutApi.listAddresses();
      if (!mounted) return;

      int? primary;
      for (final a in list) {
        if ((a["is_primary"] ?? false) == true) {
          primary = (a["id"] as num?)?.toInt();
          break;
        }
      }

      setState(() {
        addresses = list;
        selectedAddressId = primary ?? ((list.isNotEmpty) ? (list.first["id"] as num).toInt() : null);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _checkout() async {
    if (selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih alamat dulu.")),
      );
      return;
    }

    try {
      final order = await CheckoutApi.checkout(
        addressId: selectedAddressId!,
        note: noteC.text.trim(),
        items: [
          {"product_id": widget.productId, "qty": qty},
        ],
      );

      if (!mounted) return;

      final orderId = ((order["id"] ?? 0) as num).toInt();
      final orderTotal = (order["total"] as num?)?.toInt() ?? total;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            orderId: orderId,
            total: orderTotal,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checkout gagal. Cek endpoint backend.")),
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
          "Pesanan",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  const Text(
                    "Pesanan",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  _Card(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            widget.image,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(width: 56, height: 56, color: Colors.grey.shade200),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.8),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatRupiah(widget.price),
                                style: const TextStyle(
                                  color: Color(0xFFFF3B30),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _QtyPicker(
                          qty: qty,
                          onMinus: () => setState(() {
                            if (qty > 1) qty--;
                          }),
                          onPlus: () => setState(() => qty++),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    "Metode Pengantaran",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  _Card(
                    child: Row(
                      children: [
                        _SelectChip(
                          active: deliveryMethod == "pickup",
                          label: "Pickup",
                          onTap: () => setState(() => deliveryMethod = "pickup"),
                        ),
                        const SizedBox(width: 10),
                        _SelectChip(
                          active: deliveryMethod == "delivery",
                          label: "Delivery",
                          onTap: () => setState(() => deliveryMethod = "delivery"),
                        ),
                        const Spacer(),
                        Text(
                          deliveryMethod == "delivery" ? _formatRupiah(deliveryFee) : "Gratis",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    "Alamat Pengiriman",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  if (addresses.isEmpty)
                    _Card(
                      child: Text(
                        "Belum ada alamat. Buat alamat dulu di Profile.",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    )
                  else
                    ...addresses.map((a) {
                      final id = (a["id"] as num).toInt();
                      final title = (a["title"] ?? "-").toString();
                      final detail = (a["detail"] ?? "-").toString();

                      final active = id == selectedAddressId;

                      return _SelectTile(
                        active: active,
                        title: title,
                        detail: detail,
                        onTap: () => setState(() => selectedAddressId = id),
                      );
                    }),

                  const SizedBox(height: 14),

                  const Text(
                    "Catatan Pesanan (Opsional)",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: noteC,
                    decoration: InputDecoration(
                      hintText: "Contoh: tanpa sambal, ya",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    "Detail Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  _Card(
                    child: Column(
                      children: [
                        _RowPrice(label: "Subtotal", value: _formatRupiah(subtotal)),
                        const SizedBox(height: 8),
                        _RowPrice(label: "Ongkir", value: _formatRupiah(deliveryFee)),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        _RowPrice(
                          label: "Total",
                          value: _formatRupiah(total),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _checkout,
            child: const Text("Bayar Sekarang", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);

  final bool active;
  final String title;
  final String detail;
  final VoidCallback onTap;

  const _SelectTile({
    required this.active,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? kOrange : const Color(0xFFEAEAEA)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: active ? kOrange.withValues(alpha: 0.12) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: active ? kOrange : Colors.grey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                    const SizedBox(height: 3),
                    Text(detail, style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                  ],
                ),
              ),
              Icon(active ? Icons.check_circle : Icons.circle_outlined,
                  color: active ? kOrange : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);

  final bool active;
  final String label;
  final VoidCallback onTap;

  const _SelectChip({
    required this.active,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kOrange : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? kOrange : const Color(0xFFEAEAEA)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _QtyPicker extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtyPicker({required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _RowPrice extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _RowPrice({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
      color: bold ? Colors.black : Colors.grey.shade700,
      fontSize: bold ? 13 : 12.2,
    );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
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
