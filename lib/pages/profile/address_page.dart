import 'package:flutter/material.dart';
import 'package:flutter_app/services/profile_api.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  bool loading = true;
  List<Map<String, dynamic>> addresses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final a = await ProfileApi.listAddresses();
      if (!mounted) return;
      setState(() {
        addresses = a;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _openAdd() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddressPage()),
    );
    if (ok == true) _load();
  }

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
          "Tambah Alamat",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              children: [
                ...addresses.map(
                  (a) => _Tile(
                    title: (a["title"] ?? "-").toString(),
                    detail: (a["detail"] ?? "-").toString(),
                    primary: (a["is_primary"] ?? false) == true,
                  ),
                ),
                const SizedBox(height: 16),
                _Btn(text: "+ Tambah Alamat", onTap: _openAdd),
              ],
            ),
    );
  }
}

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  static const kOrange = Color(0xFFFF8A00);

  final titleC = TextEditingController();
  final detailC = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    titleC.dispose();
    detailC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = titleC.text.trim();
    final detail = detailC.text.trim();
    if (title.isEmpty || detail.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lengkapi alamat")));
      return;
    }

    setState(() => loading = true);
    try {
      await ProfileApi.addAddress(title: title, detail: detail);
      if (!mounted) return;
      setState(() => loading = false);
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal simpan alamat")));
    }
  }

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
          "Tambah Alamat",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        children: [
          _Field(
            label: "Alamat Utama",
            controller: titleC,
            hint: "Contoh: Kampus - Gedung A",
          ),
          const SizedBox(height: 12),
          _Field(
            label: "Detail Alamat",
            controller: detailC,
            hint: "Contoh: Lantai 2, Ruangan 201",
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _Btn(
                  text: "Batal",
                  color: Colors.grey.shade300,
                  textColor: Colors.black87,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Btn(
                  text: loading ? "..." : "Simpan",
                  color: kOrange,
                  textColor: Colors.white,
                  onTap: loading ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);
  final String title;
  final String detail;
  final bool primary;

  const _Tile({
    required this.title,
    required this.detail,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary
                  ? kOrange.withValues(alpha: 31)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: primary ? kOrange : Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _Btn({
    required this.text,
    this.color = const Color(0xFFFF8A00),
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
