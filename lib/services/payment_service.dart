import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_model.dart';

// Uses the classroom Edge Function invocation approach.
// Server computes the total from product IDs and quantities.
class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createInvoice(CartModel cart, Map<String, dynamic> address) async {
    final items = cart.quantities.entries
        .map((e) => {'product_id': e.key, 'quantity': e.value}).toList();
    if (items.isEmpty) throw Exception('Your cart is empty.');
    final FunctionResponse response = await _supabase.functions.invoke(
      'create-invoice', body: {'items': items, 'delivery_address': {
        'address_id': address['id'], 'full_name': address['full_name'],
        'phone': address['phone'], 'street': address['street'],
        'barangay': address['barangay'], 'city': address['city'],
        'province': address['province'], 'zip_code': address['zip_code'],
      }},
    );
    if (response.status != 200) {
      throw Exception('Could not create invoice: ${response.data}');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}
