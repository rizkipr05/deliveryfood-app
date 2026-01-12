import 'package:flutter/material.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int index = 0;

  final pages = const [
    _OnboardData(
      title: "Jelajahi Menu Favoritmu",
      desc:
          "Kemudahan dalam memesan berbagai makanan lezat dan minuman segar dari kantin kampus hanya dalam satu aplikasi.",
      imagePath: "lib/assets/1.png",
      buttonText: "Berikutnya",
    ),
    _OnboardData(
      title: "Pembayaran Instan & Aman",
      desc:
          "Nikmati proses pembayaran yang cepat dan aman dengan berbagai metode pembayaran yang tersedia.",
      imagePath: "lib/assets/2.png",
      buttonText: "Berikutnya",
    ),
    _OnboardData(
      title: "Kirim Cepat ke Mana Saja",
      desc:
          "Pesananmu akan diantar dengan cepat ke lokasi tujuan. Tinggal duduk manis!",
      imagePath: "lib/assets/3.png",
      buttonText: "Memulai",
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void next() {
    if (index < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8A00);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView.builder(
          controller: _controller,
          onPageChanged: (i) => setState(() => index = i),
          itemCount: pages.length,
          itemBuilder: (context, i) {
            final data = pages[i];
            return Column(
              children: [
                // Bagian gambar atas
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                    child: Image.asset(
                      data.imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Card putih bawah seperti contoh
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(20, 0, 0, 0),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.desc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // indikator (3 titik)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(pages.length, (dot) {
                            final active = dot == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 18 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active ? orange : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: next,
                            child: Text(
                              data.buttonText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardData {
  final String title;
  final String desc;
  final String imagePath;
  final String buttonText;

  const _OnboardData({
    required this.title,
    required this.desc,
    required this.imagePath,
    required this.buttonText,
  });
}
