import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import 'product_details_screen.dart' show productImage;

class CartScreen extends StatelessWidget {
  final List<Product> items;
  final CartModel cartModel;
  final ValueChanged<Product> onDecrease;
  final ValueChanged<Product> onAdd;
  final VoidCallback onCheckout;
  const CartScreen({super.key, required this.items, required this.cartModel, required this.onDecrease, required this.onAdd, required this.onCheckout});
  @override Widget build(BuildContext context) {
    final cart = cartModel.quantities;
    final selected = items.where((p) => (cart[p.id] ?? 0) > 0).toList();
    final subtotal = selected.fold<double>(0, (sum, p) => sum + p.price * (cart[p.id] ?? 0));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [const Expanded(child: Text('Your Cart', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900))), Text('${cartModel.itemCount} items', style: const TextStyle(color: purple))]),
      const SizedBox(height: 16),
      if (selected.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: Text('Your cart is empty. Add some gaming gear!', style: TextStyle(color: Colors.white70)))),
      ...selected.map((p) => Card(color: panel, margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        SizedBox(width: 90, height: 96, child: productImage(p)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(money(p.price), style: const TextStyle(color: purple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            IconButton(onPressed: () => onDecrease(p), visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove_circle_outline, size: 21)),
            Text('${cart[p.id]}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(onPressed: (cart[p.id] ?? 0) < p.stock ? () => onAdd(p) : null, visualDensity: VisualDensity.compact, icon: const Icon(Icons.add_circle_outline, size: 21)),
            const Spacer(),
            IconButton(tooltip: 'Remove item', onPressed: () { for (var i = 0; i < (cart[p.id] ?? 0); i++) { onDecrease(p); } }, icon: const Icon(Icons.delete_outline, color: Colors.pinkAccent)),
          ]),
        ])),
      ])))),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: purple.withOpacity(.25))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Summary', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text(money(subtotal))]),
        const SizedBox(height: 8),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Shipping'), Text('Calculated at checkout', style: TextStyle(color: Colors.white60, fontSize: 12))]),
        const Divider(height: 26),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Items total', style: TextStyle(fontWeight: FontWeight.bold)), Text(money(subtotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: purple))]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: selected.isEmpty ? null : onCheckout, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17)), child: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800)))),
      ])),
      const SizedBox(height: 12),
      const Text('Payment is handled by your existing Xendit checkout. Final charges are shown during checkout.', style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }
}
