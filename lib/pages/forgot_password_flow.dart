import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_services.dart';
import '../services/api_client.dart';

const kOrange = Color(0xFFFF8A00);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailC = TextEditingController(text: "adrian123@gmail.com");
  bool loading = false;

  @override
  void dispose() {
    emailC.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailC.text.trim();
    if (email.isEmpty) return;

    setState(() => loading = true);
    try {
      final r = await AppServices.authApi.forgotPassword(email);

      if (!mounted) return;

      // DEV: tampilkan OTP kalau backend mengembalikan devOtp
      if (r.devOtp != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("DEV OTP: ${r.devOtp}")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(r.message)));
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpPage(email: email)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ScaffoldBase(
      title: "Lupa Kata Sandi Anda",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            "Kami siap membantu Anda. Masukkan email terdaftar Anda untuk mengatur ulang kata sandi Anda, kami akan mengirimkan kode OTP ke email Anda untuk langkah selanjutnya.",
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),
          _Label("Email"),
          const SizedBox(height: 6),
          TextField(
            controller: emailC,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              hint: "email@domain.com",
              prefix: Icons.email_outlined,
            ),
          ),
          const Spacer(),
          _PrimaryButton(
            text: loading ? "Memproses..." : "Kirim Kode OTP",
            onTap: loading ? null : submit,
          ),
        ],
      ),
    );
  }
}

class OtpPage extends StatefulWidget {
  final String email;
  const OtpPage({super.key, required this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final c3 = TextEditingController();
  final c4 = TextEditingController();

  final f1 = FocusNode();
  final f2 = FocusNode();
  final f3 = FocusNode();
  final f4 = FocusNode();

  Timer? timer;
  int seconds = 56;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (seconds == 0) t.cancel();
      setState(() => seconds = (seconds > 0) ? seconds - 1 : 0);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();
    f1.dispose();
    f2.dispose();
    f3.dispose();
    f4.dispose();
    super.dispose();
  }

  String get otp => "${c1.text}${c2.text}${c3.text}${c4.text}";

  Future<void> verify() async {
    if (otp.trim().length != 4) return;

    setState(() => loading = true);
    try {
      final r = await AppServices.authApi.verifyOtp(
        email: widget.email,
        otp: otp,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(resetToken: r.resetToken),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resend() async {
    if (seconds != 0) return;
    setState(() => loading = true);
    try {
      final r = await AppServices.authApi.forgotPassword(widget.email);
      if (!mounted) return;

      if (r.devOtp != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("DEV OTP: ${r.devOtp}")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(r.message)));
      }

      setState(() => seconds = 56);
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (seconds == 0) t.cancel();
        setState(() => seconds = (seconds > 0) ? seconds - 1 : 0);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _onChange({
    required String value,
    required FocusNode current,
    FocusNode? next,
    FocusNode? prev,
    required TextEditingController controller,
  }) {
    if (value.length > 1) {
      controller.text = value.substring(value.length - 1);
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }

    if (value.isNotEmpty) {
      if (next != null) next.requestFocus();
      if (otp.trim().length == 4) verify();
    } else {
      if (prev != null) prev.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ScaffoldBase(
      title: "Masukkan Kode OTP",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            "Silakan periksa kotak masuk email Anda untuk melihat pesan. Masukkan kode verifikasi sesuai yang kami kirimkan di bawah ini.",
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OtpBox(
                controller: c1,
                focusNode: f1,
                autofocus: true,
                onChanged: (v) =>
                    _onChange(value: v, current: f1, next: f2, controller: c1),
              ),
              const SizedBox(width: 12),
              _OtpBox(
                controller: c2,
                focusNode: f2,
                onChanged: (v) => _onChange(
                  value: v,
                  current: f2,
                  next: f3,
                  prev: f1,
                  controller: c2,
                ),
              ),
              const SizedBox(width: 12),
              _OtpBox(
                controller: c3,
                focusNode: f3,
                onChanged: (v) => _onChange(
                  value: v,
                  current: f3,
                  next: f4,
                  prev: f2,
                  controller: c3,
                ),
              ),
              const SizedBox(width: 12),
              _OtpBox(
                controller: c4,
                focusNode: f4,
                onChanged: (v) =>
                    _onChange(value: v, current: f4, prev: f3, controller: c4),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                children: [
                  const TextSpan(text: "Anda dapat mengirim ulang kode dalam "),
                  TextSpan(
                    text: "${seconds}s",
                    style: const TextStyle(
                      color: kOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: " detik"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Center(
            child: TextButton(
              onPressed: (seconds == 0 && !loading) ? resend : null,
              child: Text(
                loading ? "..." : "kirim ulang kode",
                style: TextStyle(
                  color: (seconds == 0) ? kOrange : Colors.grey.shade400,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const Spacer(),
          _PrimaryButton(
            text: loading ? "Memverifikasi..." : "Verifikasi",
            onTap: (loading) ? null : verify,
          ),
        ],
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  final String resetToken;
  const ResetPasswordPage({super.key, required this.resetToken});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final pass1 = TextEditingController();
  final pass2 = TextEditingController();
  bool o1 = true;
  bool o2 = true;
  bool loading = false;

  @override
  void dispose() {
    pass1.dispose();
    pass2.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (pass1.text.length < 8 || pass2.text.length < 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Minimal 8 karakter")));
      return;
    }

    setState(() => loading = true);
    try {
      await AppServices.authApi.resetPassword(
        resetToken: widget.resetToken,
        newPassword: pass1.text,
        confirmPassword: pass2.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessResetPage()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ScaffoldBase(
      title: "Amankan Akun Anda",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            "Hampir selesai! Buat kata sandi baru untuk akun Anda agar tetap aman. Ingatlah untuk memilih kata sandi yang kuat dan unik.",
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),

          _Label("Kata Sandi Baru"),
          const SizedBox(height: 6),
          TextField(
            controller: pass1,
            obscureText: o1,
            decoration: _inputDecoration(
              hint: "••••••••••",
              prefix: Icons.lock_outline,
              suffix: IconButton(
                onPressed: () => setState(() => o1 = !o1),
                icon: Icon(o1 ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Panjangnya minimal 8 karakter!",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
          ),

          const SizedBox(height: 14),

          _Label("Konfirmasi Kata Sandi Baru"),
          const SizedBox(height: 6),
          TextField(
            controller: pass2,
            obscureText: o2,
            decoration: _inputDecoration(
              hint: "••••••••••",
              prefix: Icons.lock_outline,
              suffix: IconButton(
                onPressed: () => setState(() => o2 = !o2),
                icon: Icon(o2 ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Panjangnya minimal 8 karakter!",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
          ),

          const Spacer(),
          _PrimaryButton(
            text: loading ? "Menyimpan..." : "Simpan Kata Sandi Baru",
            onTap: loading ? null : submit,
          ),
        ],
      ),
    );
  }
}

class SuccessResetPage extends StatelessWidget {
  const SuccessResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ScaffoldBase(
      title: "Sukses",
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check, size: 42, color: kOrange),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Anda Sudah Siap!",
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            "Kata sandi Anda telah berhasil diubah",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
          const Spacer(),
          _PrimaryButton(
            text: "Buka Beranda",
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}

/// ---------- UI Components ----------

class _ScaffoldBase extends StatelessWidget {
  final String title;
  final Widget child;
  const _ScaffoldBase({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required IconData prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(prefix, size: 20),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kOrange, width: 1.4),
    ),
  );
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
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
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kOrange, width: 1.4),
          ),
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        onChanged: onChanged,
      ),
    );
  }
}
