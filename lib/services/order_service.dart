import '../services/supabase_service.dart';
import '../models/order_model.dart';

class OrderService {
  Future<List<OrderModel>> fetchOrders() async {
    final rows = await db.from('orders').select('id, amount, status, shipping_status, created_at, recipient_name, recipient_phone, delivery_address').order('created_at', ascending: false);
    return (rows as List).map((row) => OrderModel(row as Map<String, dynamic>)).toList();
  }
}
