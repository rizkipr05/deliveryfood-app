import 'package:flutter/material.dart';
import 'package:flutter_app/pages/forgot_password_flow.dart';
import 'package:flutter_app/pages/homes/home_page.dart';
import 'package:flutter_app/pages/register_page.dart';
import 'package:flutter_app/services/app_services.dart';
import 'package:flutter_app/services/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool remember = false;
  bool obscure = true;

  final emailC = TextEditingController();
  final passC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    try {
      final result = await AppServices.authApi.login(
        email: emailC.text.trim(),
        password: passC.text,
      );

      await AppServices.tokenStore.saveToken(result.token);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty ? "Login berhasil" : result.message,
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8A00);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Logo
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(15, 0, 0, 0),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset("lib/assets/4.png"),
                ),
              ),

              const SizedBox(height: 14),
              const Text(
                "Mulailah sekarang",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                "Buat akun atau masuk untuk\nmenjelajahi aplikasi kami",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 14),

              // Tab Masuk / Daftar
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
                      if (index != 1) return;
                      _tab.index = 0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
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

              const SizedBox(height: 14),

              // Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "email@domain.com",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Kata Sandi",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: passC,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: "••••••••••",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Remember + Forgot
              Row(
                children: [
                  Checkbox(
                    value: remember,
                    activeColor: orange,
                    onChanged: (v) => setState(() => remember = v ?? false),
                  ),
                  const Text("Ingat saya"),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Lupa Kata Sandi?",
                      style: TextStyle(
                        color: orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _handleLogin,
                  child: const Text(
                    "Masuk",
                    style: TextStyle(fontWeight: FontWeight.w800),
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
