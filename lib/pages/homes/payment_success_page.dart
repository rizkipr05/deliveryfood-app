import 'package:flutter/material.dart';

class PaymentSuccessPage extends StatelessWidget {
  final int orderId;
  final int total;
  final String method;
  final String deliveryMethod;

  const PaymentSuccessPage({
    super.key,
    required this.orderId,
    required this.total,
    required this.method,
    required this.deliveryMethod,
  });

  @override
  Widget build(BuildContext context) {
    final invoice = "INV$orderId".padRight(10, "");
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Nomor Pesanan",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          const SizedBox(height: 6),
          const Center(
            child: Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 64),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              "Pembayaran Berhasil!",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "Pesanan Anda sedang diproses",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Nomor Pesanan",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                Text(
                  invoice,
                  style: const TextStyle(
                    color: Color(0xFFFF8A00),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.local_shipping_outlined,
                  title: deliveryMethod == "delivery" ? "Delivery" : "Pick Up",
                  subtitle: deliveryMethod == "delivery"
                      ? "Diantar ke alamat"
                      : "Ambil di kantin sesuai tenant",
                ),
                const SizedBox(height: 8),
                const _InfoRow(
                  icon: Icons.access_time,
                  title: "Estimasi Waktu",
                  subtitle: "15-20 menit",
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  title: "Metode Pembayaran",
                  subtitle: method.toUpperCase().replaceAll("_", " "),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Card(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Metode Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                Text(
                  _formatRupiah(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
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
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text(
                  "Pesan Lagi",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFF8A00), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11.2),
              ),
            ],
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
