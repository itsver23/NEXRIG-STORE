import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  bool loading = true;
  bool authorized = false;
  String? error;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    refresh();
  }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final allowed = await AdminService().isAdmin();
      if (!allowed) {
        if (mounted) setState(() { authorized = false; loading = false; });
        return;
      }
      final p = await db.from('products').select().order('name');
      // Fetch in pages: PostgREST commonly limits responses to 1,000 rows.
      final allOrders = <Map<String, dynamic>>[];
      for (var start = 0; ; start += 500) {
        final page = await db.from('orders')
            .select('id, external_id, amount, status, shipping_status, created_at, recipient_name, recipient_phone, delivery_address, product_name')
            .order('created_at', ascending: false)
            .range(start, start + 499);
        allOrders.addAll(List<Map<String, dynamic>>.from(page));
        if (page.length < 500) break;
      }
      if (mounted) setState(() {
        authorized = true;
        products = List<Map<String, dynamic>>.from(p);
        orders = allOrders;
      });
    } catch (e) {
      if (mounted) setState(() { error = 'Unable to load dashboard: $e'; });
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> editProduct([Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: '${item?['name'] ?? ''}');
    final category = TextEditingController(text: '${item?['category'] ?? 'Peripherals'}');
    final description = TextEditingController(text: '${item?['description'] ?? ''}');
    final image = TextEditingController(text: '${item?['image_url'] ?? ''}');
    final price = TextEditingController(text: '${item?['price'] ?? ''}');
    final stock = TextEditingController(text: '${item?['stock'] ?? ''}');
    bool active = item?['is_active'] != false;
    bool saving = false;
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) {
        InputDecoration decoration(String label) => InputDecoration(
          labelText: label, floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );
        Widget field(TextEditingController controller, String label, {int lines = 1, TextInputType? type, String? Function(String?)? validator}) =>
          Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(
            controller: controller, maxLines: lines, keyboardType: type,
            decoration: decoration(label), validator: validator,
          ));
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          title: Text(item == null ? 'Add product' : 'Edit product'),
          content: SizedBox(width: 460, child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .65),
            child: Form(key: formKey, child: ListView(shrinkWrap: true, children: [
              const Text('Product information', style: TextStyle(color: Color(0xFFCA9BFF), fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              field(name, 'Product name', validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null),
              field(category, 'Category', validator: (v) => v == null || v.trim().isEmpty ? 'Category is required' : null),
              field(description, 'Description', lines: 3),
              field(image, 'Image URL or asset path'),
              field(price, 'Price (PHP)', type: const TextInputType.numberWithOptions(decimal: true), validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                return n == null || !n.isFinite || n < 0 ? 'Enter a valid price' : null;
              }),
              field(stock, 'Stock quantity', type: TextInputType.number, validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return n == null || n < 0 ? 'Enter a valid whole number' : null;
              }),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible in store'),
                subtitle: Text(active ? 'Customers can see this product' : 'Hidden from customers'),
                value: active, onChanged: saving ? null : (v) => setDialogState(() => active = v),
              ),
            ])),
          )),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => saving = true);
                try {
                  final data = <String, dynamic>{
                    'name': name.text.trim(), 'category': category.text.trim(),
                    'description': description.text.trim(), 'image_url': image.text.trim(),
                    'price': double.parse(price.text.trim()), 'stock': int.parse(stock.text.trim()),
                    'is_active': active,
                  };
                  if (item == null) {
                    final inserted = await db.from('products').insert(data).select('id').maybeSingle();
                    if (inserted == null) throw StateError('Insert returned no product. Check Supabase RLS INSERT and SELECT policies.');
                  } else {
                    final updated = await db.from('products').update(data).eq('id', item['id']).select('id').maybeSingle();
                    if (updated == null) throw StateError('No product updated. Check product ID and Supabase RLS UPDATE/SELECT policies.');
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Supabase save failed: $e')));
                    setDialogState(() => saving = false);
                  }
                }
              },
              icon: saving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
              label: Text(saving ? 'Saving...' : 'Save product'),
            ),
          ],
        );
      }),
    );
    name.dispose(); category.dispose(); description.dispose(); image.dispose(); price.dispose(); stock.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(item == null ? 'Product added to Supabase.' : 'Product updated in Supabase.')));
      await refresh();
    }
  }

  Future<void> updateShipping(Map<String, dynamic> order, String status) async {
    try {
      final updated = await db.rpc('admin_update_shipping_status', params: {
        'p_order_id': order['id'], 'p_status': status,
      });
      if (updated != true) throw StateError('Order not found or not updated.');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shipment status updated to ${status.toUpperCase()}')));
      await refresh();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'))); }
  }


  static const bg = Color(0xFF090C19);
  static const surface = Color(0xFF161B2D);
  static const accent = Color(0xFF9D20F5);

  String peso(dynamic amount) {
    final n = amount is num ? amount : num.tryParse('$amount') ?? 0;
    return '₱${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';
  }

  Widget heading(String title, String subtitle, IconData icon) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF321354), Color(0xFF15182D), Color(0xFF101426)])),
    child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      const SizedBox(height: 8), Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ])), Icon(icon, size: 43, color: accent)]),
  );

  Widget tile(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 11), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFF30354D))),
    child: child,
  );

  Widget productTile(Map<String, dynamic> p) {
    final url = '${p['image_url'] ?? ''}';
    final visible = p['is_active'] != false;
    return tile(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(9), child: Container(width: 80, height: 90, color: const Color(0xFF242A3E),
        child: url.isEmpty ? const Icon(Icons.memory, size: 34) : (url.startsWith('http://') || url.startsWith('https://') ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 34)) : Image.asset(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 34))))),
      const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${p['name'] ?? 'Product'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), Text(peso(p['price']), style: const TextStyle(color: Color(0xFFD9A4FF), fontWeight: FontWeight.bold)),
        const SizedBox(height: 5), Text('Stock: ${p['stock'] ?? 0}  •  ${visible ? 'Visible' : 'Hidden'}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 5), Wrap(spacing: 5, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Chip(label: Text(visible ? 'Visible' : 'Hidden', style: const TextStyle(fontSize: 11)), backgroundColor: visible ? const Color(0xFF116444) : const Color(0xFF623143), visualDensity: VisualDensity.compact),
          IconButton(tooltip: 'Edit product', onPressed: () => editProduct(p), icon: const Icon(Icons.edit_outlined, color: accent)),
          
        ]),
      ])),
    ]));
  }

  Widget orderTile(Map<String, dynamic> o) {
    final current = '${o['shipping_status'] ?? 'pending'}'.toLowerCase();
    const statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
    final color = current == 'pending' ? Colors.blueAccent : current == 'processing' ? Colors.greenAccent : current == 'shipped' ? Colors.orangeAccent : current == 'cancelled' ? Colors.redAccent : accent;
    return tile(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Order #${o['external_id'] ?? o['id']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
        Chip(label: Text(current.toUpperCase(), style: const TextStyle(fontSize: 10)), backgroundColor: color.withValues(alpha: .2), side: BorderSide(color: color))]),
      const SizedBox(height: 5), Text('${o['recipient_name'] ?? 'Customer'}', style: const TextStyle(color: Color(0xFFD9A4FF))),
      const SizedBox(height: 5), Text('${o['created_at'] ?? ''}'.replaceFirst('T', ' ').split('.').first, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      const SizedBox(height: 8), Row(children: [Text(peso(o['amount']), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const Spacer(), Text('Payment: ${o['status'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.white70))]),
      const Divider(height: 23),
      Row(children: [Expanded(child: OutlinedButton(onPressed: () => showOrder(o), child: const Text('View Details'))), const SizedBox(width: 10),
        Expanded(child: DropdownButtonFormField<String>(value: statuses.contains(current) ? current : null, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Shipping', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 9, vertical: 10)),
          items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (s) { if (s != null && s != current) updateShipping(o, s); }))]),
    ]));
  }

  Future<void> showOrder(Map<String, dynamic> o) async {
    if (!mounted) return;
    showDialog<void>(context: context, builder: (c) => AlertDialog(
      title: const Text('Order Details'),
      content: SizedBox(width: 440, child: FutureBuilder<List<Map<String, dynamic>>>(
        future: db.from('order_items')
            .select('quantity, unit_price, product_id, products(name)')
            .eq('order_id', o['id'])
            .then((rows) => List<Map<String, dynamic>>.from(rows)),
        builder: (context, snapshot) => SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText('Order: ${o['external_id'] ?? o['id']}\n\nCustomer: ${o['recipient_name'] ?? 'Not provided'}\nPhone: ${o['recipient_phone'] ?? 'Not provided'}\nAddress: ${o['delivery_address'] ?? 'Not provided'}\n\nTotal: ${peso(o['amount'])}\nPayment: ${o['status']}\nShipping: ${o['shipping_status']}\nDate: ${o['created_at']}'),
            const SizedBox(height: 16),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
            else if (snapshot.hasError)
              Text('Unable to load order items: ${snapshot.error}')
            else if ((snapshot.data ?? []).isEmpty)
              const Text('No order items found')
            else
              ...snapshot.data!.map((item) {
                final product = item['products'];
                final name = product is Map ? '${product['name'] ?? 'Product'}' : 'Product';
                return Padding(padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('$name × ${item['quantity']} — ${peso(item['unit_price'])} each'));
              }),
          ],
        )),
      )),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
    ));
  }

  Widget productTab() => _ProductTab(products: products, heading: heading, tile: productTile, add: () => editProduct());
  Widget ordersTab() => _OrderTab(orders: orders, heading: heading, tile: orderTile);

  @override
  Widget build(BuildContext context) => Theme(data: Theme.of(context).copyWith(
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
    appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: Colors.white),
  ), child: Scaffold(
    appBar: AppBar(title: const Row(children: [Icon(Icons.view_in_ar, color: accent, size: 29), SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NEXRIG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21, letterSpacing: 2)), Text('A D M I N', style: TextStyle(fontSize: 10, letterSpacing: 3))])]), actions: [
      IconButton(tooltip: 'Refresh', onPressed: refresh, icon: const Icon(Icons.refresh)),
      IconButton(tooltip: 'Logout', icon: const Icon(Icons.logout_outlined), onPressed: () async {
        await AuthService().logout();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const StorePage()), (_) => false);
      }),
    ]),
    body: loading ? const Center(child: CircularProgressIndicator()) :
      !authorized ? Center(child: Text(error ?? 'Admin access denied.')) :
      error != null ? Center(child: Text(error!)) :
      Column(children: [
        TabBar(controller: _tabController, indicatorColor: accent, labelColor: accent, unselectedLabelColor: Colors.white70, tabs: [Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'), Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders')]),
        Expanded(child: TabBarView(controller: _tabController, children: [productTab(), ordersTab()])),
      ]),
  ));
}

class _ProductTab extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Widget Function(String, String, IconData) heading;
  final Widget Function(Map<String, dynamic>) tile;
  final VoidCallback add;
  const _ProductTab({required this.products, required this.heading, required this.tile, required this.add});
  @override State<_ProductTab> createState() => _ProductTabState();
}
class _ProductTabState extends State<_ProductTab> {
  String search = '', filter = 'All';
  @override Widget build(BuildContext context) {
    final data = widget.products.where((p) => '${p['name']} ${p['category']}'.toLowerCase().contains(search.toLowerCase()) &&
      (filter == 'All' || (filter == 'Visible' ? p['is_active'] != false : p['is_active'] == false))).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      widget.heading('Products Management', 'Add, edit, and manage your products.', Icons.desktop_windows_outlined),
      const SizedBox(height: 14), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: widget.add, icon: const Icon(Icons.add), label: const Text('Add Product'), style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)))),
      const SizedBox(height: 14), TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search products...', border: OutlineInputBorder())),
      Row(children: [const Text('Filter:  '), DropdownButton<String>(value: filter, items: ['All', 'Visible', 'Hidden'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => filter = v ?? 'All')), const Spacer(), Text('${data.length} products', style: const TextStyle(color: Colors.white70))]),
      if (data.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No products found'))),
      ...data.map(widget.tile),
    ]);
  }
}
class _OrderTab extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final Widget Function(String, String, IconData) heading;
  final Widget Function(Map<String, dynamic>) tile;
  const _OrderTab({required this.orders, required this.heading, required this.tile});
  @override State<_OrderTab> createState() => _OrderTabState();
}
class _OrderTabState extends State<_OrderTab> {
  String search = '', filter = 'All';
  @override Widget build(BuildContext context) {
    final data = widget.orders.where((o) => '${o['id']} ${o['external_id']} ${o['recipient_name']} ${o['recipient_phone']}'.toLowerCase().contains(search.toLowerCase()) &&
      (filter == 'All' || '${o['shipping_status'] ?? 'pending'}'.toLowerCase() == filter)).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      widget.heading('Orders Management', 'View and update customer orders.', Icons.local_shipping_outlined),
      const SizedBox(height: 14), TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search orders or customers...', border: OutlineInputBorder())),
      Row(children: [const Text('Status:  '), DropdownButton<String>(value: filter, items: ['All', 'pending', 'processing', 'shipped', 'delivered', 'cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => filter = v ?? 'All')), const Spacer(), Text('${data.length} orders', style: const TextStyle(color: Colors.white70))]),
      if (data.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No orders found'))),
      ...data.map(widget.tile),
    ]);
  }
}
