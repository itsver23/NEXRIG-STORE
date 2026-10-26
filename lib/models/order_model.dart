class OrderModel {
  final String id, status, shippingStatus, createdAt;
  final double amount;
  final String recipientName, recipientPhone, deliveryAddress;
  OrderModel(Map<String, dynamic> data)
      : id = data['id'].toString(),
        status = (data['status'] ?? 'PENDING').toString(),
        shippingStatus = (data['shipping_status'] ?? 'pending').toString(),
        createdAt = (data['created_at'] ?? '').toString(),
        amount = (data['amount'] as num).toDouble(),
        recipientName = (data['recipient_name'] ?? '').toString(),
        recipientPhone = (data['recipient_phone'] ?? '').toString(),
        deliveryAddress = (data['delivery_address'] ?? '').toString();
}
