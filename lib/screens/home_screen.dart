import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../services/product_service.dart';
import '../services/payment_service.dart';
import 'account_screen.dart';
import 'shop_screen.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'xendit_webview_screen.dart';
import 'checkout_address_screen.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> with SingleTickerProviderStateMixin {
  List<Product> items = [];
  final CartModel cart = CartModel();
  bool loading = true;
  String? error;
  String search = '';
  int tab = 0;
  String? category;
  final Set<String> wishlist = {};
  final GlobalKey _bottomCartKey = GlobalKey();
  late final AnimationController _flyController;
  OverlayEntry? _flight;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 800));
    refresh();
    loadWishlist();
  }

  @override
  void dispose() {
    _flight?.remove();
    _flight?.dispose();
    _flyController.dispose();
    super.dispose();
  }

  Future<void> loadWishlist() async {
    final user = db.auth.currentUser;
    if (user == null) { if (mounted) setState(wishlist.clear); return; }
    try {
      final rows = await db.from('wishlists').select('product_id').eq('user_id', user.id);
      if (mounted) setState(() {
        wishlist..clear()..addAll((rows as List).map((r) => r['product_id'].toString()));
      });
    } catch (e) { debugPrint('Wishlist loading: $e'); }
  }

  Future<void> toggleWishlist(Product product) async {
    final user = db.auth.currentUser;
    if (user == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage()));
      if (!mounted) return;
      if (db.auth.currentUser == null) return;
      await loadWishlist();
    }
    final id = db.auth.currentUser!.id;
    final already = wishlist.contains(product.id);
    try {
      if (already) {
        await db.from('wishlists').delete().eq('user_id', id).eq('product_id', product.id);
      } else {
        await db.from('wishlists').insert({'user_id': id, 'product_id': product.id});
      }
      if (mounted) setState(() {
        if (already) { wishlist.remove(product.id); } else { wishlist.add(product.id); }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wishlist unavailable. Please check setup.')));
    }
  }

  Rect? _rect(GlobalKey key) {
    final object = key.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return null;
    return object.localToGlobal(Offset.zero) & object.size;
  }

  Future<void> addFromShop(Product product, GlobalKey sourceKey) async {
    if (_adding || product.stock <= 0) return;
    _adding = true;
    final startRect = _rect(sourceKey);
    final endRect = _rect(_bottomCartKey);
    final overlay = Overlay.of(context);
    final box = overlay.context.findRenderObject();
    if (startRect != null && endRect != null && box is RenderBox) {
      final origin = box.localToGlobal(Offset.zero);
      final start = startRect.center - origin;
      final end = endRect.center - origin;
      final flight = CurvedAnimation(parent: _flyController, curve: Curves.easeInOutCubic);
      _flight = OverlayEntry(builder: (_) => AnimatedBuilder(
        animation: _flyController, builder: (context, child) {
          final t = flight.value;
          final center = Offset.lerp(start, end, t)!;
          final side = 54.0 - 20.0 * t;
          return Positioned(
            left: center.dx - side / 2,
            top: center.dy - side / 2 - 45 * (1 - (2 * t - 1) * (2 * t - 1)),
            width: side, height: side,
            child: IgnorePointer(child: Opacity(
              opacity: (1 - t * .25).clamp(0.0, 1.0),
              child: DecoratedBox(decoration: BoxDecoration(color: panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: purple, width: 2),
                boxShadow: [BoxShadow(color: purple.withOpacity(.45), blurRadius: 20)]),
                child: const Center(child: Icon(Icons.shopping_bag_rounded,
                  color: Colors.white, size: 25))),
            )),
          );
        }));
      overlay.insert(_flight!);
      try { await _flyController.forward(from: 0); } finally {
        _flight?.remove(); _flight?.dispose(); _flight = null;
      }
    }
    if (mounted) add(product);
    _adding = false;
  }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final products = await ProductService().fetchProducts();
      if (mounted) setState(() { items = products; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = '$e'; loading = false; });
    }
  }

  void add(Product item) {
    if (!cart.add(item)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock')));
      return;
    }
    setState(() {});
    // No persistent SnackBar: the cart badge reflects the new quantity.
  }

  void openProduct(Product item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        product: item,
        cartCount: cart.itemCount,
        onAdd: (product, quantity) {
          var added = 0;
          for (var i = 0; i < quantity; i++) {
            if (!cart.add(product)) break;
            added++;
          }
          if (added > 0) {
            Navigator.of(context).pop(); // Return to Shop after adding.
            setState(() => tab = 0);
          } else {
            setState(() {});
          }
          if (added == 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Not enough stock'),
              duration: Duration(seconds: 2),
            ));
          }
        },
        onViewCart: () {
          Navigator.of(context).pop();
          setState(() => tab = 1);
        },
      ),
    ));
  }

  Future<void> checkout() async {
    if (db.auth.currentUser == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage()));
      if (db.auth.currentUser == null) return;
    }
    final address = await Navigator.push<Map<String, dynamic>>(context,
      MaterialPageRoute(builder: (_) => const CheckoutAddressScreen()));
    if (!mounted || address == null) return;
    try {
      final invoice = await PaymentService().createInvoice(cart, address);
      final invoiceUrl = (invoice['invoice_url'] ?? '').toString();
      if (invoiceUrl.isEmpty) throw Exception('Missing invoice URL');
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => XenditWebViewScreen(invoiceUrl: invoiceUrl),
      ));
      if (!mounted) return;
      setState(() { cart.clear(); tab = 2; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Check your payment status in Orders. Refresh after paying.'),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> selectTab(int index) async {
    if (index == 3 && db.auth.currentUser == null) {
      // Profile was tapped by a guest: open Login / Register directly.
      await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AccountPage()));
      if (!mounted) return;
      // A successful login or registration returns to the Shop.
      setState(() => tab = 0);
      await loadWishlist();
      return;
    }
    setState(() => tab = index);
    if (db.auth.currentUser != null) loadWishlist();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: const Column(mainAxisSize: MainAxisSize.min, children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'NEX', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'RIG', style: TextStyle(color: Color(0xFFB74CFF))),
        ]), style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 21)),
        Text('S T O R E', style: TextStyle(fontSize: 9, letterSpacing: 2.0)),
      ]),
    ),
    body: tab == 0
      ? ShopScreen(items: items, loading: loading, error: error, search: search,
          onSearch: (value) => setState(() => search = value), onRefresh: refresh,
          onAdd: addFromShop, onOpen: openProduct, wishlist: wishlist,
          onWishlist: toggleWishlist, category: category,
          onCategory: (value) => setState(() => category = value))
      : tab == 1
      ? CartScreen(items: items, cartModel: cart,
          onDecrease: (item) => setState(() => cart.decrease(item)), onAdd: add, onCheckout: checkout)
      : tab == 2
      ? OrdersScreen(onStartShopping: () => setState(() => tab = 0))
      : ProfileScreen(onLoggedOut: () => setState(() => tab = 0)),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: selectTab,
      destinations: [
        const NavigationDestination(icon: Icon(Icons.storefront), label: 'Shop'),
        NavigationDestination(icon: SizedBox(key: _bottomCartKey, width: 32, height: 32,
          child: Center(child: Badge(label: Text('${cart.itemCount}'),
            child: const Icon(Icons.shopping_cart)))), label: 'Cart'),
        const NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    ),
  );
}
