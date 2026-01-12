import 'package:flutter/material.dart';

class SuccessPage extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: kOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 14),
              const Text(
                "Anda Sudah Siap!",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                "Kata sandi Anda telah berhasil diubah",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  height: 46,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      "Kembali ke Beranda",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
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
