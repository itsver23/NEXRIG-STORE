import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';

/// Show the entire supplied product image without cropping it.
Widget productImage(Product p, {double size = 90}) {
  final placeholder = Icon(Icons.memory, size: size * .55, color: purple);
  final url = p.imageUrl.trim();
  if (url.startsWith('http')) {
    return Image.network(url, fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => placeholder);
  }
  if (url.startsWith('assets/')) {
    return Image.asset(url, fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => placeholder);
  }
  return placeholder;
}

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final void Function(Product, int) onAdd;
  final VoidCallback onViewCart;
  final int cartCount;

  const ProductDetailsScreen({super.key, required this.product,
    required this.onAdd, required this.onViewCart, required this.cartCount});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  int quantity = 1;
  bool _flying = false;
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _cartKey = GlobalKey();
  late final AnimationController _flyController;
  OverlayEntry? _flyingEntry;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _flyingEntry?.remove();
    _flyingEntry?.dispose();
    _flyController.dispose();
    super.dispose();
  }

  Rect? _globalRect(GlobalKey key) {
    final object = key.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return null;
    final origin = object.localToGlobal(Offset.zero);
    return origin & object.size;
  }

  Future<void> _addWithAnimation() async {
    if (_flying || widget.product.stock <= 0) return;
    setState(() => _flying = true);

    final source = _globalRect(_addButtonKey);
    final destination = _globalRect(_cartKey);
    final overlay = Overlay.of(context);

    if (source != null && destination != null) {
      final overlayBox = overlay.context.findRenderObject();
      if (overlayBox is RenderBox) {
        final origin = overlayBox.localToGlobal(Offset.zero);
        final start = source.center - origin;
        final end = destination.center - origin;
        final flight = CurvedAnimation(parent: _flyController,
            curve: Curves.easeInOutCubic);

        _flyingEntry = OverlayEntry(builder: (_) => AnimatedBuilder(
          animation: _flyController,
          builder: (context, child) {
            final t = flight.value;
            final center = Offset.lerp(start, end, t)!;
            final side = 54.0 - 20.0 * t;
            return Positioned(
              left: center.dx - side / 2,
              top: center.dy - side / 2 - 45 * (1 - (2 * t - 1) * (2 * t - 1)),
              width: side, height: side,
              child: IgnorePointer(child: Opacity(
                opacity: (1 - t * .25).clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: panel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: purple, width: 2),
                    boxShadow: [BoxShadow(color: purple.withOpacity(.45), blurRadius: 20)]),
                  child: const Center(child: Icon(Icons.shopping_bag_rounded,
                    color: Colors.white, size: 25)),
                ),
              )),
            );
          },
        ));
        overlay.insert(_flyingEntry!);
        try {
          await _flyController.forward(from: 0);
        } finally {
          _flyingEntry?.remove();
          _flyingEntry?.dispose();
          _flyingEntry = null;
        }
      }
    }
    if (!mounted) return;
    // Parent updates the real cart and returns to Shop after the flight.
    widget.onAdd(widget.product, quantity);
    if (mounted) setState(() => _flying = false);
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label,
        style: const TextStyle(color: Colors.white60))),
      Expanded(child: Text(value,
        style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRODUCT DETAILS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
            letterSpacing: 2)),
        actions: [
          IconButton(
            onPressed: _flying ? null : widget.onViewCart,
            tooltip: 'View cart (${widget.cartCount} items)',
            icon: SizedBox(key: _cartKey, width: 32, height: 32,
              child: Center(child: Badge(
                isLabelVisible: widget.cartCount > 0,
                label: Text('${widget.cartCount}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ))),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: purple.withOpacity(.25))),
          child: Center(child: SizedBox.expand(child: productImage(p, size: 240))),
        ),
        const SizedBox(height: 22),
        Text(p.category.toUpperCase(), style: const TextStyle(
          color: purple, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(money(p.price), style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w800, color: purple)),
        const SizedBox(height: 6),
        Text(p.stock > 0 ? '${p.stock} in stock' : 'Out of stock',
          style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: panel,
            borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Product Details', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold)),
            const Divider(height: 22),
            Text(p.description.trim().isEmpty
              ? 'No additional description has been provided for this product yet.'
              : p.description,
              style: const TextStyle(height: 1.5, color: Colors.white70)),
            const SizedBox(height: 16),
            const Text('Product Information', style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _infoRow('Category', p.category),
            _infoRow('Availability', p.stock > 0 ? '${p.stock} in stock' : 'Out of stock'),
            _infoRow('Price', money(p.price)),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Container(decoration: BoxDecoration(color: panel,
            borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              IconButton(onPressed: !_flying && quantity > 1
                ? () => setState(() => quantity--) : null,
                icon: const Icon(Icons.remove)),
              Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(onPressed: !_flying && quantity < p.stock
                ? () => setState(() => quantity++) : null,
                icon: const Icon(Icons.add)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(key: _addButtonKey, child: FilledButton.icon(
            onPressed: p.stock > 0 && !_flying ? _addWithAnimation : null,
            icon: Icon(_flying ? Icons.check_circle_outline : Icons.shopping_bag_outlined),
            label: Text(_flying ? 'Adding...' : 'Add to Cart'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18)),
          ))),
        ]),
        const SizedBox(height: 28),
      ]),
    );
  }
}
