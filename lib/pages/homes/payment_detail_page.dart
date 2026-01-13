import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/checkout_api.dart';
import 'payment_success_page.dart';

class PaymentDetailPage extends StatefulWidget {
  final int orderId;
  final int total;
  final String method;
  final String? paymentUrl;
  final String? paymentQr;
  final String merchantName;
  final String deliveryMethod;

  const PaymentDetailPage({
    super.key,
    required this.orderId,
    required this.total,
    required this.method,
    this.paymentUrl,
    this.paymentQr,
    this.merchantName = "Warung Pak Tri",
    this.deliveryMethod = "pickup",
  });

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  static const kOrange = Color(0xFFFF8A00);

  Timer? _timer;
  Timer? _poller;
  Duration _remaining = const Duration(minutes: 30);
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = _remaining - const Duration(seconds: 1);
        }
      });
    });
    _poller = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkStatus();
    });
    _checkStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _poller?.cancel();
    super.dispose();
  }

  String get _timeLeft {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, "0");
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "00:$m:$s";
  }

  String get _methodLabel {
    switch (widget.method) {
      case "bank_transfer":
        return "Bank Transfer";
      case "cash":
        return "Cash";
      default:
        return "QRIS (Semua Bank & E-Wallet)";
    }
  }

  Future<void> _checkStatus() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final res = await CheckoutApi.paymentStatus(orderId: widget.orderId);
      final paid = res["paid"] == true;
      if (!mounted) return;
      if (paid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              orderId: widget.orderId,
              total: widget.total,
              method: widget.method,
              deliveryMethod: widget.deliveryMethod,
            ),
          ),
        );
      }
    } catch (_) {
      // ignore transient errors
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = (widget.paymentQr ?? "").isNotEmpty
        ? widget.paymentQr!
        : (widget.paymentUrl ?? "");

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Detail Pembayaran",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Metode Pembayaran",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _methodLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Batas Waktu Bayar",
                          style: TextStyle(color: Color(0xFFFF3B30), fontSize: 10.5),
                        ),
                        Text(
                          _timeLeft,
                          style: const TextStyle(
                            color: Color(0xFFFF3B30),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Jumlah yang harus\nDibayar:",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatRupiah(widget.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF3B30),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Scan barcode di bawah ini menggunakan aplikasi Bank/E-Wallet pilihan Anda. Pastikan nama merchant adalah ${widget.merchantName}.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          if (qrData.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF6A3D), width: 2),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    size: 200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Merchant: ${widget.merchantName}",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Gunakan aplikasi yang mendukung QRIS\n(Gojek, Dana, Mobile Banking).",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                  ),
                  if ((widget.paymentUrl ?? "").isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.paymentUrl!),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Link QR disalin.")),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF8A00)),
                        foregroundColor: const Color(0xFFFF8A00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("Salin Link QR"),
                    ),
                  ],
                ],
              ),
            )
          else
            _Card(
              child: Column(
                children: [
                  const Text(
                    "QR belum tersedia.",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Buka link pembayaran atau cek kembali setelah beberapa saat.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                  ),
                  if ((widget.paymentUrl ?? "").isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.paymentUrl!),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Link pembayaran disalin.")),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("Salin Link Pembayaran"),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF6A3D)),
            ),
            child: const Text(
              "Barcode hanya berlaku selama batas waktu yang di atas. Jangan tutup laman ini.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFF3B30), fontSize: 11.5),
            ),
          ),
        ],
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
