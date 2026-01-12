import 'package:flutter/material.dart';
import 'package:flutter_app/services/profile_api.dart';
import 'package:flutter_app/services/app_services.dart';
import 'edit_profile_page.dart';
import 'address_page.dart';
import 'account_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const kOrange = Color(0xFFFF8A00);

  bool loading = true;
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> addresses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    Map<String, dynamic>? me;
    List<Map<String, dynamic>> addr = [];

    try {
      me = await ProfileApi.me();
    } catch (_) {}

    try {
      addr = await ProfileApi.listAddresses();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      user = me;
      addresses = addr;
      loading = false;
    });
  }

  Future<void> _logout() async {
    await AppServices.tokenStore.clear();
    if (!mounted) return;

    // Karena ProfilePage ini TAB (IndexedStack), kita tidak pop route.
    // Cukup kembali ke root agar HomePage reload (sesuai flow app kamu).
    Navigator.of(context).popUntil((r) => r.isFirst);

    // Optional: kalau HomePage kamu butuh refresh user, biasanya akan reload sendiri.
  }

  @override
  Widget build(BuildContext context) {
    final name = (user?["name"] ?? "User").toString();
    final email = (user?["email"] ?? "").toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        "Profil Saya",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ===== Header Card =====
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2740),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                image: AssetImage("lib/assets/5.png"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 217),
                                fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Alamat Pengiriman header =====
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Alamat Pengiriman",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddressPage(),
                              ),
                            );
                            _load();
                          },
                          child: const Text(
                            "+ Tambah",
                            style: TextStyle(
                              color: kOrange,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (addresses.isEmpty)
                      const _EmptyHint(
                        text: "Belum ada alamat. Tambahkan alamat dulu.",
                      )
                    else
                      ...addresses
                          .take(2)
                          .map(
                            (a) => _AddressTile(
                              title: (a["title"] ?? "-").toString(),
                              detail: (a["detail"] ?? "-").toString(),
                              primary: (a["is_primary"] ?? false) == true,
                            ),
                          ),

                    const SizedBox(height: 14),

                    // ===== Menu =====
                    _MenuTile(
                      icon: Icons.edit_outlined,
                      label: "Edit Profil",
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfilePage(user: user),
                          ),
                        );
                        if (updated == true) _load();
                      },
                    ),
                    const SizedBox(height: 10),
                    _MenuTile(
                      icon: Icons.lock_outline,
                      label: "Account Security",
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _MenuTile(
                      icon: Icons.logout,
                      label: "Logout",
                      onTap: _logout,
                    ),

                    const SizedBox(height: 6),
                ],
              ),
            ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);

  final String title;
  final String detail;
  final bool primary;

  const _AddressTile({
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
              size: 18,
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black87),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }
}
