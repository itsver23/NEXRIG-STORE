// Product model based on the classroom Product.fromMap pattern.
class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final String imageUrl;
  final double price;
  final int stock;

  Product({required this.id, required this.name, required this.category,
    required this.description, required this.imageUrl, required this.price, required this.stock});

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'Unnamed Product').toString(),
      category: (map['category'] ?? 'Peripherals').toString(),
      description: (map['description'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      price: (map['price'] as num? ?? 0).toDouble(),
      stock: (map['stock'] as num? ?? 0).toInt(),
    );
  }
}
