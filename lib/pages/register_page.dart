import 'package:flutter/material.dart';
import '../services/app_services.dart';
import '../services/api_client.dart';

// kalau kamu punya LoginPage, import di sini
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  static const kOrange = Color(0xFFFF8A00);

  late final TabController _tab;

  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final phoneC = TextEditingController(text: "(+62) 5623 9007 876");
  final passC = TextEditingController();

  bool obscure = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.index = 1; // default ke "Daftar"
  }

  @override
  void dispose() {
    _tab.dispose();
    nameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> submitRegister() async {
    final name = nameC.text.trim();
    final email = emailC.text.trim();
    final pass = passC.text;

    if (name.length < 2) {
      _toast("Nama minimal 2 karakter");
      return;
    }
    if (!email.contains("@")) {
      _toast("Email tidak valid");
      return;
    }
    if (pass.length < 8) {
      _toast("Password minimal 8 karakter");
      return;
    }

    setState(() => loading = true);
    try {
      await AppServices.authApi.register(
        name: name,
        email: email,
        password: pass,
      );

      if (!mounted) return;

      _toast("Daftar berhasil, silakan login");

      // setelah register, arahkan ke LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (e) {
      if (!mounted) return;
      _toast("Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // LOGO
              Center(
                child: Container(
                  width: 86,
                  height: 86,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset("lib/assets/4.png"),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                "Mulailah sekarang",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                "Buat akun atau masuk untuk\nmenjelajahi aplikasi kami",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.3),
              ),

              const SizedBox(height: 16),

              // Tab Masuk/Daftar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  height: 42,
                  child: TabBar(
                    controller: _tab,
                    onTap: (index) {
                      if (index != 0) return;
                      _tab.index = 1;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      });
                    },
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    splashBorderRadius: BorderRadius.circular(10),
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey.shade600,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: "Masuk"),
                      Tab(text: "Daftar"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // FORM
              _Label("Nama Lengkap"),
              const SizedBox(height: 6),
              TextField(
                controller: nameC,
                decoration: _inputDecoration(
                  hint: "Nama lengkap",
                  prefix: Icons.person_outline,
                ),
              ),

              const SizedBox(height: 12),

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

              const SizedBox(height: 12),

              _Label("Nomor Telepon"),
              const SizedBox(height: 6),
              TextField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  hint: "(+62) 8xxx xxxx xxxx",
                  prefix: Icons.phone_outlined,
                ),
              ),

              const SizedBox(height: 12),

              _Label("Kata Sandi"),
              const SizedBox(height: 6),
              TextField(
                controller: passC,
                obscureText: obscure,
                decoration: _inputDecoration(
                  hint: "••••••••••",
                  prefix: Icons.lock_outline,
                  suffix: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Panjangnya minimal 8 karakter!",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                ),
              ),

              const SizedBox(height: 18),

              // BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: loading ? null : submitRegister,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Daftar",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
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
      borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 1.4),
    ),
  );
}
