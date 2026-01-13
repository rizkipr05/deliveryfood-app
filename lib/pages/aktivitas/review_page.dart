import 'package:flutter/material.dart';
import '../../services/review_api.dart';

class ReviewPage extends StatefulWidget {
  final int productId;
  final String productName;

  const ReviewPage({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int star = 5;
  final noteC = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    noteC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      await ReviewApi.addReview(
        productId: widget.productId,
        star: star,
        comment: noteC.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengirim ulasan.")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Beri Nilai",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final active = i < star;
              return IconButton(
                onPressed: () => setState(() => star = i + 1),
                icon: Icon(
                  active ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB300),
                  size: 28,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: TextField(
              controller: noteC,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Tulis Ulasan Anda (minimal 10 kata)...",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA200), Color(0xFFFF3B30)],
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : _submit,
                child: Text(
                  loading ? "Mengirim..." : "Kirim Review",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
