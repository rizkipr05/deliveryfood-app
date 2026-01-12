import 'package:flutter/material.dart';
import 'package:flutter_app/services/profile_api.dart';
import 'otp_page.dart';

class ChangePasswordPage extends StatefulWidget {
  final String email;
  const ChangePasswordPage({super.key, required this.email});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldC = TextEditingController();
  final newC = TextEditingController();
  final confirmC = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    oldC.dispose();
    newC.dispose();
    confirmC.dispose();
    super.dispose();
  }

  Future<void> _goOtp() async {
    if (newC.text.trim().length < 8) {
      _snack("Password baru minimal 8 karakter");
      return;
    }
    if (newC.text.trim() != confirmC.text.trim()) {
      _snack("Konfirmasi password tidak sama");
      return;
    }

    setState(() => loading = true);
    try {
      await ProfileApi.requestOtp(email: widget.email);
      if (!mounted) return;
      setState(() => loading = false);

      // lanjut OTP screen, bawa payload password
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            email: widget.email,
            oldPassword: oldC.text.trim(),
            newPassword: newC.text.trim(),
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _snack("Gagal kirim OTP");
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
          "Edit Kata Sandi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        children: [
          _Field(label: "Email", initial: widget.email, enabled: false),
          const SizedBox(height: 10),
          _Field(label: "Kata Sandi Lama", controller: oldC, obscure: true),
          const SizedBox(height: 10),
          _Field(
            label: "Kata Sandi Baru",
            controller: newC,
            obscure: true,
            helper: "Panjangnya minimal 8 karakter!",
          ),
          const SizedBox(height: 10),
          _Field(
            label: "Konfirmasi Kata Sandi Baru",
            controller: confirmC,
            obscure: true,
            helper: "Panjangnya minimal 8 karakter!",
          ),
          const SizedBox(height: 18),
          _Btn(
            text: loading ? "..." : "Simpan Kata Sandi",
            onTap: loading ? null : _goOtp,
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initial;
  final bool enabled;
  final bool obscure;
  final String? helper;

  const _Field({
    required this.label,
    this.controller,
    this.initial,
    this.enabled = true,
    this.obscure = false,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller ?? TextEditingController(text: initial ?? "");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          enabled: enabled,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);
  final String text;
  final VoidCallback? onTap;
  const _Btn({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 46,
        decoration: BoxDecoration(
          color: kOrange,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
