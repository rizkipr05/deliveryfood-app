import 'package:flutter/material.dart';
import 'package:flutter_app/services/profile_api.dart';
import 'success_page.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final String oldPassword;
  final String newPassword;

  const OtpPage({
    super.key,
    required this.email,
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const kOrange = Color(0xFFFF8A00);

  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final c3 = TextEditingController();
  final c4 = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();
    super.dispose();
  }

  String get otp => "${c1.text}${c2.text}${c3.text}${c4.text}".trim();

  Future<void> _submit() async {
    if (otp.length != 4) {
      _snack("OTP harus 4 digit");
      return;
    }

    setState(() => loading = true);
    try {
      await ProfileApi.verifyOtp(email: widget.email, otp: otp);

      // setelah OTP valid, ubah password
      await ProfileApi.changePassword(
        email: widget.email,
        oldPassword: widget.oldPassword,
        newPassword: widget.newPassword,
      );

      if (!mounted) return;
      setState(() => loading = false);

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessPage()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _snack("OTP salah / gagal ubah password");
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Masukkan Kode OTP",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Silakan periksa kotak masuk email Anda untuk melihat pesan dari sistem. Masukkan kode verifikasi sekali pakai di bawah ini.",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OtpBox(controller: c1),
                _OtpBox(controller: c2),
                _OtpBox(controller: c3),
                _OtpBox(controller: c4),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                "Anda dapat mengirim ulang kode dalam 56 detik",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                "Kirim ulang kode",
                style: TextStyle(
                  color: kOrange,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: loading ? null : _submit,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                height: 46,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    loading ? "..." : "Verifikasi",
                    style: const TextStyle(
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
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  const _OtpBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
          ),
        ),
      ),
    );
  }
}
