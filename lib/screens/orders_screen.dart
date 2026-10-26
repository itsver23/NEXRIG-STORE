import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
import '../services/order_service.dart';
import 'account_screen.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback onStartShopping;
  const OrdersScreen({super.key, required this.onStartShopping});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderModel>> ordersFuture;

  @override
  void initState() {
    super.initState();
    ordersFuture = OrderService().fetchOrders();
  }

  Future<void> _refresh() async {
    final updated = OrderService().fetchOrders();
    setState(() => ordersFuture = updated);
    try {
      await updated;
    } catch (_) {
      // FutureBuilder displays the error message.
    }
  }

  Widget _emptyOrders() {
    return Padding(
      padding: const EdgeInsets.only(top: 55),
      child: Card(
        color: panel,
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(children: [
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFF302044),
              child: Icon(Icons.inventory_2_outlined, color: purple, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('No Orders Yet', style: TextStyle(
              fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'You have not placed an order yet. Explore our PC parts and build your dream setup!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: widget.onStartShopping,
              icon: const Icon(Icons.storefront),
              label: const Text('Start Shopping'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    final shipping = order.shippingStatus.toLowerCase();
    final paid = order.status.toUpperCase() == 'PAID';
    final shippingLabel = paid
        ? (shipping == 'pending' ? 'Preparing Order' :
            '${shipping[0].toUpperCase()}${shipping.substring(1)}')
        : order.status.toUpperCase();
    String date = order.createdAt;
    try {
      final parsed = DateTime.parse(order.createdAt).toLocal();
      date = '${parsed.month}/${parsed.day}/${parsed.year}';
    } catch (_) {}

    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Order #${_shortId(order.id)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
            Flexible(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF302044),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(shippingLabel, textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFCC8CFF), fontSize: 12)),
            )),
          ]),
          const SizedBox(height: 8),
          Text('Placed: $date', style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0C16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: purple.withOpacity(.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.local_shipping_outlined, color: purple, size: 18),
                  SizedBox(width: 7),
                  Text('SHIP TO / DELIVERY DETAILS',
                    style: TextStyle(color: purple, fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
                const SizedBox(height: 10),
                _detailLine(Icons.person_outline, 'Recipient',
                    order.recipientName.isEmpty ? 'Not saved' : order.recipientName),
                const SizedBox(height: 7),
                _detailLine(Icons.phone_outlined, 'Phone',
                    order.recipientPhone.isEmpty ? 'Not saved' : order.recipientPhone),
                const SizedBox(height: 7),
                _detailLine(Icons.location_on_outlined, 'Address',
                    order.deliveryAddress.isEmpty ? 'No delivery address saved' : order.deliveryAddress),
              ],
            ),
          ),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Amount', style: TextStyle(color: Colors.white70)),
            Text(money(order.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Payment', style: TextStyle(color: Colors.white70)),
            Text(order.status.toUpperCase(), style: TextStyle(
                color: paid ? Colors.greenAccent : Colors.orangeAccent,
                fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => OrderTrackingPage(order: order),
              ));
              if (mounted) _refresh();
            },
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Track Order'),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (db.auth.currentUser == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('MY ORDERS', style: TextStyle(
            fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('Track and manage your purchases',
            style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 35),
          Card(
            color: panel,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xFF302044),
                    child: Icon(Icons.lock_outline, color: purple, size: 40),
                  ),
                  const SizedBox(height: 18),
                  const Text('Sign In Required', style: TextStyle(
                    fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign in to your NEXRIG account to view your orders and track your deliveries.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const AccountPage(),
                      ));
                      if (!mounted) return;
                      setState(() {
                        if (db.auth.currentUser != null) {
                          ordersFuture = OrderService().fetchOrders();
                        }
                      });
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In / Register'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<OrderModel>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text('MY ORDERS', style: TextStyle(
                  fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text('Track and manage your purchases',
                  style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(padding: EdgeInsets.only(top: 70),
                    child: Center(child: CircularProgressIndicator())),
              if (snapshot.hasError)
                Card(color: panel, child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    const Text('Unable to load your orders.'),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _refresh, child: const Text('Try Again')),
                  ]),
                )),
              if (snapshot.hasData && snapshot.data!.isEmpty) _emptyOrders(),
              if (snapshot.hasData)
                ...snapshot.data!.map((order) => _orderCard(order)),
            ],
          );
        },
      ),
    );
  }
}

Widget _detailLine(IconData icon, String label, String value) {
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: Colors.white60, size: 17),
    const SizedBox(width: 8),
    SizedBox(width: 70, child: Text(label,
      style: const TextStyle(color: Colors.white60, fontSize: 12))),
    Expanded(child: Text(value,
      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3))),
  ]);
}

String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

class OrderTrackingPage extends StatelessWidget {
  final OrderModel order;
  const OrderTrackingPage({super.key, required this.order});

  int _progress(String paymentStatus, String shippingStatus) {
    if (paymentStatus.toUpperCase() != 'PAID') return 0;
    switch (shippingStatus.toLowerCase()) {
      case 'delivered': return 4;
      case 'shipped': return 3;
      case 'processing': return 2;
      default: return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Order Placed', 'Payment Confirmed', 'Processing', 'Shipped', 'Delivered',
    ];
    final status = order.status.toUpperCase();
    final isCancelled = status == 'CANCELLED' || status == 'EXPIRED' || status == 'FAILED';
    final progress = isCancelled ? -1 : _progress(status, order.shippingStatus);

    return Scaffold(
      appBar: AppBar(title: const Text('ORDER TRACKING'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Card(color: panel, child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Order #${_shortId(order.id)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Payment: ${order.status}',
                style: const TextStyle(color: purple, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Shipping: ${order.shippingStatus}',
                style: const TextStyle(color: purple)),
            const SizedBox(height: 8),
            Text('Placed: ${order.createdAt}'),
            const SizedBox(height: 8),
            Text('Amount: ${money(order.amount)}'),
          ]),
        )),
        if (order.recipientName.isNotEmpty) ...[
          const SizedBox(height: 18),
          Card(color: panel, child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Delivery Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Recipient: ${order.recipientName}'),
              Text('Phone: ${order.recipientPhone}'),
              Text('Address: ${order.deliveryAddress}'),
            ]),
          )),
        ],
        const SizedBox(height: 18),
        Card(color: panel, child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Order Tracking', style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            if (isCancelled)
              Text('Order status: ${order.status}. Tracking is unavailable.',
                  style: const TextStyle(color: Colors.orangeAccent)),
            if (!isCancelled)
              ...List.generate(steps.length, (index) {
                final reached = index <= progress;
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    Icon(reached ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: reached ? purple : Colors.white38, size: 23),
                    if (index != steps.length - 1)
                      Container(width: 2, height: 34,
                          color: index < progress ? purple : Colors.white24),
                  ]),
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(steps[index], style: TextStyle(
                        color: reached ? Colors.white : Colors.white54,
                        fontWeight: reached ? FontWeight.bold : FontWeight.normal)),
                  ),
                ]);
              }),
            const SizedBox(height: 12),
            const Text('Tracking reflects the latest order status saved in Supabase. '
                'Delivery dates are not available yet.',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        )),
      ]),
    );
  }
}
