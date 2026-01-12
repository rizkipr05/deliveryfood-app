import 'package:flutter/material.dart';
import 'package:flutter_app/services/profile_api.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const kOrange = Color(0xFFFF8A00);

  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameC.text = (widget.user?["name"] ?? "").toString();
    phoneC.text = (widget.user?["phone"] ?? "").toString();
  }

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameC.text.trim();
    final phone = phoneC.text.trim();

    if (name.isEmpty) {
      _snack("Nama wajib diisi");
      return;
    }
    setState(() => loading = true);

    try {
      await ProfileApi.updateProfile(name: name, phone: phone);
      if (!mounted) return;
      setState(() => loading = false);
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _snack("Gagal menyimpan");
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        children: [
          Center(
            child: Column(
              children: const [
                SizedBox(height: 10),
                CircleAvatar(
                  radius: 34,
                  backgroundImage: AssetImage("lib/assets/5.png"),
                ),
                SizedBox(height: 8),
                Text(
                  "Change Profile Photo",
                  style: TextStyle(
                    color: kOrange,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _Field(
            label: "Nama Lengkap",
            controller: nameC,
            suffix: const Icon(Icons.edit, size: 18),
          ),
          const SizedBox(height: 12),
          _Field(label: "Nomor Telepon", controller: phoneC),

          const SizedBox(height: 24),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Widget? suffix;

  const _Field({required this.label, required this.controller, this.suffix});

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
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.orange.shade300, width: 1.2),
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
    required this.color,
    required this.textColor,
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
