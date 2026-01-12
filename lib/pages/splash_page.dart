import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool showLogo = false;

  @override
  void initState() {
    super.initState();

    // splash kosong 1 detik
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => showLogo = true);
    });

    // lalu pindah ke onboarding
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8A00);

    return Scaffold(
      backgroundColor: orange,
      body: Center(
        child: AnimatedOpacity(
          opacity: showLogo ? 1 : 0,
          duration: const Duration(milliseconds: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Image.asset("lib/assets/4.png", fit: BoxFit.contain),
              ),
              const SizedBox(height: 14),
              const Text(
                "incanteen!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
