import '../services/supabase_service.dart';
import '../models/product_model.dart';

class ProductService {
  Future<List<Product>> fetchProducts() async {
    final rows = await db.from('products').select().eq('is_active', true).order('name');
    return (rows as List).map((row) => Product.fromMap(row as Map<String, dynamic>)).toList();
  }
}
