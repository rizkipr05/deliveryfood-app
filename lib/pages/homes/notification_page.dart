import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifikasi",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: const [
          _NotifTile(
            title: "Pesananmu sedang diproses",
            detail: "Burger Spesial sedang disiapkan oleh merchant.",
            time: "2 menit lalu",
            active: true,
          ),
          _NotifTile(
            title: "Pembayaran berhasil",
            detail: "Pembayaran order #1023 telah dikonfirmasi.",
            time: "1 jam lalu",
          ),
          _NotifTile(
            title: "Promo spesial hari ini",
            detail: "Diskon 20% untuk semua menu makanan.",
            time: "Kemarin",
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String title;
  final String detail;
  final String time;
  final bool active;

  const _NotifTile({
    required this.title,
    required this.detail,
    required this.time,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    const kOrange = Color(0xFFFF8A00);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: active ? kOrange.withValues(alpha: 0.12) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: active ? kOrange : Colors.grey,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.8),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5),
                ),
              ],
            ),
          ),
          if (active)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: kOrange,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
