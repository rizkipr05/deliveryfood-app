import 'package:flutter/material.dart';
import '../../services/checkout_api.dart';

class PaymentPage extends StatefulWidget {
  final int orderId;
  final int total;
  final String method;
  final String? paymentUrl;

  const PaymentPage({
    super.key,
    required this.orderId,
    required this.total,
    required this.method,
    this.paymentUrl,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const kOrange = Color(0xFFFF8A00);

  bool loading = false;

  Future<void> _confirm() async {
    setState(() => loading = true);
    try {
      await CheckoutApi.confirmPayment(orderId: widget.orderId, method: widget.method);
      if (!mounted) return;
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran berhasil dikonfirmasi")),
      );

      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konfirmasi gagal. Cek endpoint backend.")),
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
          "Payment",
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
          _Card(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Total Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
                Text(
                  _formatRupiah(widget.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Metode Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
                Text(
                  widget.method.toUpperCase().replaceAll("_", " "),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kOrange,
                  ),
                ),
              ],
            ),
          ),
          if ((widget.paymentUrl ?? "").isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Link Pembayaran (Sandbox)",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    widget.paymentUrl!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: loading ? null : _confirm,
            child: Text(
              loading ? "Memproses..." : "Konfirmasi",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
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
