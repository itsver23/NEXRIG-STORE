import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../config/app_theme.dart';
import '../models/product_model.dart';
import 'product_details_screen.dart';

class ShopScreen extends StatelessWidget {
  final List<Product> items;
  final bool loading;
  final String? error;
  final String search;
  final ValueChanged<String> onSearch;
  final Future<void> Function() onRefresh;
  final void Function(Product, GlobalKey) onAdd;
  final ValueChanged<Product> onOpen;
  final Set<String> wishlist;
  final ValueChanged<Product> onWishlist;
  final String? category;
  final ValueChanged<String?> onCategory;
  const ShopScreen({super.key, required this.items, required this.loading,
    required this.error, required this.search, required this.onSearch,
    required this.onRefresh, required this.onAdd, required this.onOpen,
    required this.wishlist, required this.onWishlist, required this.category,
    required this.onCategory});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Unable to load products: $error'));
    final q = search.trim().toLowerCase();
    final visible = items.where((p) {
      final matches = '${p.name} ${p.category} ${p.description}'.toLowerCase().contains(q);
      return matches && (category == null || _normalizeCategory(p.category) == _normalizeCategory(category!));
    }).toList();
    visible.sort((a, b) {
      final aWish = wishlist.contains(a.id) ? 0 : 1;
      final bWish = wishlist.contains(b.id) ? 0 : 1;
      return aWish.compareTo(bWish);
    });
    const categories = ['Cases', 'CPU Cooling', 'Graphics Cards', 'Keyboards', 'Memory', 'Mouse', 'Monitors', 'Motherboards', 'Power Supplies', 'Processors', 'Storage'];
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 850 ? 4 : width >= 600 ? 3 : 2;
    return RefreshIndicator(onRefresh: onRefresh, child: ListView(
      padding: const EdgeInsets.all(14), children: [
      TextField(onChanged: onSearch, controller: TextEditingController.fromValue(
        TextEditingValue(text: search, selection: TextSelection.collapsed(offset: search.length))),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search products...')),
      const SizedBox(height: 14),
      Container(height: 160, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
        image: const DecorationImage(image: AssetImage('assets/hero_alt.webp'), fit: BoxFit.cover)),
        child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [Color(0xE9080916), Color(0x22080916)])),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('NEXT LEVEL\nGAMING SETUP', style: TextStyle(fontSize: 23,
              fontWeight: FontWeight.w900, height: 1.1)),
            SizedBox(height: 8), Text('Premium PC Components\nfor Every Gamer'),
          ]))),
      const SizedBox(height: 14),
      SizedBox(height: 74, child: ListView(scrollDirection: Axis.horizontal, children: [
        _categoryButton('All', Icons.apps, category == null, () => onCategory(null)),
        for (final c in categories) _categoryButton(c, _categoryIcon(c),
          category == c, () => onCategory(category == c ? null : c)),
      ])),
      const SizedBox(height: 16),
      Text(q.isEmpty && category == null ? 'Featured Products' : 'Search Results',
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('${visible.length} products found', style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 12),
      if (visible.isEmpty) const Padding(padding: EdgeInsets.all(32),
        child: Center(child: Text('No matching products found.'))),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: visible.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns, crossAxisSpacing: 9, mainAxisSpacing: 9,
          mainAxisExtent: 302),
        itemBuilder: (context, index) {
          final p = visible[index];
          final buttonKey = GlobalKey();
          return Card(color: panel, margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias,
            child: Padding(padding: const EdgeInsets.all(9), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Stack(children: [
                Positioned.fill(child: InkWell(onTap: () => onOpen(p),
                  child: Padding(padding: const EdgeInsets.all(8),
                    child: Center(child: SizedBox.expand(
                      child: productImage(p, size: 120)))))),
                Positioned(top: 0, right: 0, child: IconButton(
                  tooltip: 'Wishlist', icon: Icon(
                    wishlist.contains(p.id) ? Icons.favorite : Icons.favorite_border,
                    color: wishlist.contains(p.id) ? purple : Colors.white70),
                  onPressed: () => onWishlist(p))),
              ])),
              const SizedBox(height: 6),
              Text(p.category.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: purple)),
              InkWell(onTap: () => onOpen(p), child: SizedBox(height: 40,
                child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))),
              Text(money(p.price), style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: purple)),
              Text(p.stock > 0 ? 'In Stock: ${p.stock}' : 'Out of Stock',
                style: TextStyle(fontSize: 11, color: p.stock > 0 ? Colors.white60 : Colors.redAccent)),
              const SizedBox(height: 7),
              SizedBox(key: buttonKey, width: double.infinity, height: 36,
                child: FilledButton(onPressed: p.stock > 0 ? () => onAdd(p, buttonKey) : null,
                  style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(p.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(fontSize: 12)))),
            ])));
        }),
      const SizedBox(height: 20),
    ]));
  }

  Widget _categoryButton(String label, IconData icon, bool active, VoidCallback tap) =>
    Padding(padding: const EdgeInsets.only(right: 8), child: InkWell(onTap: tap,
      child: Container(width: 104, padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? purple : Colors.white12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: purple, size: 25), const SizedBox(height: 5),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11)),
        ]))));

  String _normalizeCategory(String name) {
    final s = name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const aliases = {
      'case': 'cases', 'pccase': 'cases', 'chassis': 'cases',
      'cooler': 'cpucooling', 'cpucooler': 'cpucooling', 'cooling': 'cpucooling', 'fans': 'cpucooling', 'cpufan': 'cpucooling',
      'gpu': 'graphicscards', 'graphicscard': 'graphicscards', 'videocard': 'graphicscards',
      'keyboard': 'keyboards', 'ram': 'memory', 'mice': 'mouse', 'mouse': 'mouse',
      'monitor': 'monitors', 'motherboard': 'motherboards',
      'psu': 'powersupplies', 'powersupply': 'powersupplies',
      'cpu': 'processors', 'processor': 'processors',
      'ssd': 'storage', 'hdd': 'storage', 'harddrive': 'storage',
    };
    return aliases[s] ?? s;
  }

  IconData _categoryIcon(String name) {
    final s = name.toLowerCase();
    if (s == 'cases') return Icons.computer;
    if (s == 'cpu cooling') return Icons.ac_unit;
    if (s.contains('graphic') || s.contains('gpu')) return Icons.videogame_asset;
    if (s == 'keyboards') return Icons.keyboard;
    if (s == 'mouse') return Icons.mouse;
    if (s == 'monitors') return Icons.desktop_windows;
    if (s == 'powersupplies') return Icons.power;
    if (s.contains('processor') || s.contains('cpu')) return Icons.memory;
    if (s.contains('motherboard')) return Icons.developer_board;
    if (s.contains('ram') || s.contains('memory')) return Icons.storage;
    if (s.contains('storage') || s.contains('ssd')) return Icons.sd_storage;
    return Icons.computer;
  }
}
