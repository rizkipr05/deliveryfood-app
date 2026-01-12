import 'package:flutter/material.dart';
import '../../services/checkout_api.dart';

class PaymentPage extends StatefulWidget {
  final int orderId;
  final int total;

  const PaymentPage({super.key, required this.orderId, required this.total});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const kOrange = Color(0xFFFF8A00);

  String method = "ewallet";
  bool loading = false;

  Future<void> _confirm() async {
    setState(() => loading = true);
    try {
      await CheckoutApi.confirmPayment(orderId: widget.orderId, method: method);
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
          const SizedBox(height: 14),
          const Text(
            "Metode Pembayaran",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _PayTile(
            active: method == "cash",
            title: "Cash",
            subtitle: "Bayar di tempat",
            icon: Icons.payments_outlined,
            onTap: () => setState(() => method = "cash"),
          ),
          _PayTile(
            active: method == "ewallet",
            title: "E-Wallet",
            subtitle: "OVO / DANA / GoPay",
            icon: Icons.phone_iphone,
            onTap: () => setState(() => method = "ewallet"),
          ),
          _PayTile(
            active: method == "bank",
            title: "Transfer Bank",
            subtitle: "Virtual Account",
            icon: Icons.account_balance_outlined,
            onTap: () => setState(() => method = "bank"),
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

class _PayTile extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);

  final bool active;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PayTile({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.icon,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: active ? kOrange.withValues(alpha: 0.12) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: active ? kOrange : Colors.grey, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.8)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
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
