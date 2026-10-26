import 'product_model.dart';

class CartModel {
  final Map<String, int> quantities = {};
  int quantityFor(Product item) => quantities[item.id] ?? 0;
  int get itemCount => quantities.values.fold(0, (a, b) => a + b);
  double total(List<Product> products) => products.fold(0.0, (sum, p) => sum + p.price * quantityFor(p));
  bool add(Product item) {
    if (quantityFor(item) >= item.stock) return false;
    quantities[item.id] = quantityFor(item) + 1;
    return true;
  }
  void decrease(Product item) {
    final count = quantityFor(item) - 1;
    if (count <= 0) { quantities.remove(item.id); } else { quantities[item.id] = count; }
  }
  void clear() => quantities.clear();
}
