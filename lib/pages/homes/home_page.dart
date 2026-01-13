import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../services/api_client.dart';
import '../promo/promo_page.dart';
import '../profile/profile_page.dart';
import 'product_detail_page.dart';
import 'cart_page.dart';
import 'notification_page.dart';
import '../aktivitas/activity_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchC = TextEditingController();
  int selectedCat = 0;
  int bottomIndex = 0;

  String userName = "User";
  String? avatarUrl;
  bool loadingUser = true;

  bool loadingProducts = true;
  List<_FoodItem> items = [];

  Timer? _debounce;

  final categories = const ["Semua", "Makanan", "Minuman", "Snacks", "Dessert"];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchC.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final token = await AppServices.tokenStore.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          userName = "User";
          loadingUser = false;
        });
        return;
      }

      final user = await AppServices.authApi.me(token);

      if (!mounted) return;
      setState(() {
        userName = (user["name"] ?? "User").toString();
        avatarUrl = (user["avatar_url"] ?? "").toString();
        if (avatarUrl != null && avatarUrl!.isEmpty) avatarUrl = null;
        loadingUser = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => loadingUser = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingUser = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => loadingProducts = true);

    try {
      final cat = categories[selectedCat];
      final q = searchC.text.trim();

      final qp = <String, String>{};
      if (cat.isNotEmpty) qp["category"] = cat;
      if (q.isNotEmpty) qp["q"] = q;

      final path = qp.isEmpty
          ? "/api/products"
          : "/api/products?${Uri(queryParameters: qp).query}";

      final res = await AppServices.apiClient.get(path);
      final list = (res["data"] as List).cast<dynamic>();

      final mapped = list.map<_FoodItem>((e) {
        final m = (e as Map).cast<String, dynamic>();

        final img = (m["image"] ?? "").toString().trim();
        final imagePath = img.isEmpty
            ? "lib/assets/produk/burger.png"
            : "lib/assets/produk/$img";

        final id = (m["id"] as num?)?.toInt() ?? 0;

        return _FoodItem(
          id: id,
          cat: (m["category"] ?? "Semua").toString(),
          name: (m["name"] ?? "").toString(),
          store: (m["store"] ?? "").toString(),
          price: (m["price"] as num).toInt(),
          rating: (m["rating"] as num).toDouble(),
          image: imagePath,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        items = mapped;
        loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingProducts = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // ✅ FIX: jangan SafeArea di sini (biar bottom bar gak ke-dobel padding)
      body: IndexedStack(
        index: bottomIndex,
        children: [
          _homeTab(context),
          const PromoPage(),
          const ActivityPage(),
          const ProfilePage(),
        ],
      ),

      bottomNavigationBar: _BottomBar(
        index: bottomIndex,
        onChange: (i) => setState(() => bottomIndex = i),
      ),
    );
  }

  Widget _homeTab(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _TopHeader(
            name: loadingUser ? "..." : userName,
            avatarUrl: avatarUrl,
            onCartTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
            onNotifTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          _SearchBar(
            controller: searchC,
            onChanged: (v) => _onSearchChanged(v),
          ),
          const SizedBox(height: 12),
          _PromoBanner(onTap: () => setState(() => bottomIndex = 1)),
          const SizedBox(height: 12),
          const _SectionTitle(title: "Kategori"),
          const SizedBox(height: 8),
          _CategoryChips(
            categories: categories,
            selectedIndex: selectedCat,
            onSelected: (i) {
              setState(() => selectedCat = i);
              _loadProducts();
            },
          ),
          const SizedBox(height: 10),
          _SectionTitle(title: _sectionByCategory(categories[selectedCat])),
          const SizedBox(height: 8),
          Expanded(
            child: loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _FoodTile(
                        item: items[i],
                        onTap: () {
                          final item = items[i];
                          final id = item.id;
                          if (id <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Produk tidak ditemukan."),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(
                                productId: id,
                                initialData: {
                                  "id": id,
                                  "name": item.name,
                                  "store": item.store,
                                  "price": item.price,
                                  "rating": item.rating,
                                  "image": item.image,
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static String _sectionByCategory(String cat) {
    switch (cat) {
      case "Makanan":
        return "Makanan";
      case "Minuman":
        return "Minuman";
      case "Snacks":
        return "Snacks";
      case "Dessert":
        return "Dessert";
      default:
        return "Populer";
    }
  }
}

// ========================= placeholder =========================
class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }
}

// ========================= UI Widgets =========================

class _TopHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final VoidCallback onCartTap;
  final VoidCallback onNotifTap;

  const _TopHeader({
    required this.name,
    required this.avatarUrl,
    required this.onCartTap,
    required this.onNotifTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: _avatarProvider(avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat Datang",
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _IconSquareButton(
            icon: Icons.shopping_cart_outlined,
            onTap: onCartTap,
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _IconSquareButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotifTap,
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconSquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}

ImageProvider _avatarProvider(String? dataUrl) {
  if (dataUrl == null || dataUrl.isEmpty) {
    return const AssetImage("lib/assets/5.png");
  }
  if (dataUrl.startsWith("data:image")) {
    final idx = dataUrl.indexOf(",");
    if (idx != -1) {
      final b64 = dataUrl.substring(idx + 1);
      return MemoryImage(base64Decode(b64));
    }
  }
  if (dataUrl.startsWith("http")) {
    return NetworkImage(dataUrl);
  }
  return const AssetImage("lib/assets/5.png");
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: "Cari makanan...",
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
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
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PromoBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              "lib/assets/6.png",
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final active = i == selectedIndex;
          return InkWell(
            onTap: () => onSelected(i),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: active ? kOrange : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? kOrange : const Color(0xFFEAEAEA),
                ),
              ),
              child: Text(
                categories[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  final _FoodItem item;
  final VoidCallback onTap;

  const _FoodTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                item.image,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.store,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFFFB300),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${item.rating.toStringAsFixed(1)} / 5.0",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatRupiah(item.price),
              style: const TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;

  const _BottomBar({required this.index, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomItem(
                active: index == 0,
                icon: Icons.home_rounded,
                label: "Home",
                onTap: () => onChange(0),
              ),
            ),
            Expanded(
              child: _BottomItem(
                active: index == 1,
                icon: Icons.explore_outlined,
                label: "Promo",
                onTap: () => onChange(1),
              ),
            ),
            Expanded(
              child: _BottomItem(
                active: index == 2,
                icon: Icons.receipt_long_outlined,
                label: "Aktivitas",
                onTap: () => onChange(2),
              ),
            ),
            Expanded(
              child: _BottomItem(
                active: index == 3,
                icon: Icons.person_outline,
                label: "Profile",
                onTap: () => onChange(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  static const kOrange = Color(0xFFFF8A00);

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomItem({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? kOrange.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? kOrange : Colors.grey.shade500,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: active ? kOrange : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================= Model + Utils =========================

class _FoodItem {
  final int id;
  final String cat;
  final String name;
  final String store;
  final int price;
  final double rating;
  final String image;

  const _FoodItem({
    required this.id,
    required this.cat,
    required this.name,
    required this.store,
    required this.price,
    required this.rating,
    required this.image,
  });
}

String _formatRupiah(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(".");
  }
  return "Rp ${buf.toString()}";
}
