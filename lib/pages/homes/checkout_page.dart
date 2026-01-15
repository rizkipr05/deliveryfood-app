import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/checkout_api.dart';
import 'payment_detail_page.dart';
import 'payment_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final int productId;
  final String name;
  final String? store;
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
    this.store,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const kOrange = Color(0xFFFF8A00);

  String deliveryMethod = "pickup";
  String paymentMethod = "qris";
  String bankCode = "bca";
  int qty = 1;
  bool submitting = false;

  final addressC = TextEditingController();
  final noteC = TextEditingController();

  int get subtotal => widget.price * qty;
  int get deliveryFee => deliveryMethod == "delivery" ? 5000 : 0;
  int get total => subtotal + deliveryFee;

  @override
  void initState() {
    super.initState();
    qty = widget.qty;
  }

  @override
  void dispose() {
    addressC.dispose();
    noteC.dispose();
    super.dispose();
  }

  String get _paymentLabel {
    switch (paymentMethod) {
      case "cash":
        return "Cash";
      case "bank_transfer":
        return bankCode == "mandiri" ? "Mandiri Bill" : "VA ${bankCode.toUpperCase()}";
      default:
        return "QRIS";
    }
  }

  Future<void> _checkout() async {
    if (deliveryMethod == "delivery" && addressC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi alamat pengiriman dulu.")),
      );
      return;
    }

    setState(() => submitting = true);
    try {
      final order = await CheckoutApi.checkout(
        productId: widget.productId,
        qty: qty,
        paymentMethod: paymentMethod,
        deliveryMethod: deliveryMethod,
        bankCode: paymentMethod == "bank_transfer" ? bankCode : null,
        address: deliveryMethod == "delivery" ? addressC.text.trim() : "",
        note: noteC.text.trim(),
      );

      if (!mounted) return;

      final orderId = ((order["id"] ?? 0) as num).toInt();
      final orderTotal = (order["total"] as num?)?.toInt() ?? total;
      final paymentUrl = (order["payment_url"] ?? "").toString();
      final paymentQr = (order["payment_qr"] ?? "").toString();
      final orderBankCode = (order["bank_code"] ?? "").toString();
      final orderVaNumber = (order["va_number"] ?? "").toString();
      final orderVaExpiredAt = (order["va_expired_at"] ?? "").toString();
      final orderBillerCode = (order["biller_code"] ?? "").toString();
      final orderBillKey = (order["bill_key"] ?? "").toString();

      if (paymentMethod == "cash") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              orderId: orderId,
              total: orderTotal,
              method: paymentMethod,
              deliveryMethod: deliveryMethod,
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentDetailPage(
            orderId: orderId,
            total: orderTotal,
            paymentUrl: paymentUrl.isEmpty ? null : paymentUrl,
            paymentQr: paymentQr.isEmpty ? null : paymentQr,
            bankCode: orderBankCode.isEmpty ? null : orderBankCode,
            vaNumber: orderVaNumber.isEmpty ? null : orderVaNumber,
            vaExpiredAt: orderVaExpiredAt.isEmpty ? null : orderVaExpiredAt,
            billerCode: orderBillerCode.isEmpty ? null : orderBillerCode,
            billKey: orderBillKey.isEmpty ? null : orderBillKey,
            method: paymentMethod,
            merchantName: widget.store ?? "Warung Pak Tri",
            deliveryMethod: deliveryMethod,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checkout gagal. Cek endpoint backend.")),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _openPaymentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        String temp = paymentMethod;
        String tempBank = bankCode;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final bankOptions = const [
              {"code": "bca", "label": "BCA"},
              {"code": "bni", "label": "BNI"},
              {"code": "bri", "label": "BRI"},
              {"code": "mandiri", "label": "Mandiri Bill"},
              {"code": "permata", "label": "Permata"},
            ];
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Payment Method",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Your security and privacy are protected",
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    _PayTile(
                      title: "Cash",
                      icon: Icons.payments_outlined,
                      active: temp == "cash",
                      onTap: () => setLocal(() => temp = "cash"),
                    ),
                    _PayTile(
                      title: "QRIS",
                      icon: Icons.qr_code_rounded,
                      active: temp == "qris",
                      onTap: () => setLocal(() => temp = "qris"),
                    ),
                    _PayTile(
                      title: "Bank Transfer",
                      icon: Icons.account_balance_outlined,
                      active: temp == "bank_transfer",
                      onTap: () => setLocal(() => temp = "bank_transfer"),
                    ),
                    if (temp == "bank_transfer") ...[
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Pilih Bank VA",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: bankOptions
                            .map(
                              (bank) => _BankChip(
                                label: bank["label"] ?? "",
                                active: tempBank == bank["code"],
                                onTap: () => setLocal(() => tempBank = bank["code"] ?? ""),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              paymentMethod = temp;
                              if (temp == "bank_transfer") {
                                bankCode = tempBank;
                              }
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            "Melanjutkan",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _SectionTitle("Pesanan"),
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
                        widget.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      if ((widget.store ?? "").isNotEmpty)
                        Text(
                          widget.store!,
                          style: TextStyle(color: Colors.orange.shade700, fontSize: 11.5),
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
          const SizedBox(height: 12),
          _Card(
            child: InkWell(
              onTap: _openPaymentSheet,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Metode Pembayaran",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ),
                  Text(
                    _paymentLabel,
                    style: const TextStyle(
                      color: kOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MethodChip(
                label: "Pick Up",
                active: deliveryMethod == "pickup",
                onTap: () => setState(() => deliveryMethod = "pickup"),
              ),
              const SizedBox(width: 10),
              _MethodChip(
                label: "Delivery",
                active: deliveryMethod == "delivery",
                onTap: () => setState(() => deliveryMethod = "delivery"),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionTitle("Detail Pembayaran"),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              children: [
                _RowPrice(label: "Subtotal Produk", value: _formatRupiah(subtotal)),
                const SizedBox(height: 8),
                _RowPrice(label: "Biaya Layanan", value: _formatRupiah(deliveryFee)),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _RowPrice(
                  label: "Total Pembayaran",
                  value: _formatRupiah(total),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (deliveryMethod == "delivery") ...[
            _SectionTitle("Alamat Pengiriman"),
            const SizedBox(height: 10),
            _Card(
              child: TextField(
                controller: addressC,
                decoration: const InputDecoration(
                  hintText: "Contoh: Gedung A, Lantai 2, Ruangan 201",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _SectionTitle("Catatan Pesanan (Opsional)"),
          const SizedBox(height: 10),
          _Card(
            child: TextField(
              controller: noteC,
              decoration: const InputDecoration(
                hintText: "Contoh: Tidak pakai sambel...",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
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
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: submitting ? null : _checkout,
                child: Text(
                  submitting ? "Memproses..." : "Bayar Sekarang",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFFFF8A00) : const Color(0xFFEAEAEA)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFFF8A00) : Colors.grey.shade600,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _BankChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BankChip({
    required this.label,
    required this.active,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFFFF8A00) : const Color(0xFFEAEAEA)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFFF8A00) : Colors.grey.shade600,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _PayTile({
    required this.title,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFF8A00), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.8),
              ),
            ),
            Icon(
              active ? Icons.radio_button_checked : Icons.radio_button_off,
              color: active ? const Color(0xFFFF8A00) : Colors.grey.shade400,
            ),
          ],
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
    return Row(
      children: [
        InkWell(
          onTap: onMinus,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              "−",
              style: TextStyle(
                color: kOrange,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: kOrange,
            shape: BoxShape.circle,
          ),
          child: Text(
            "$qty",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onPlus,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              "+",
              style: TextStyle(
                color: kOrange,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
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
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      color: bold ? Colors.black : Colors.grey.shade700,
      fontSize: bold ? 13 : 12,
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
