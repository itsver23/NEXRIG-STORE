import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';
import 'addresses_screen.dart';

// Returns a copy of the selected address to checkout.
class CheckoutAddressScreen extends StatefulWidget {
  const CheckoutAddressScreen({super.key});
  @override
  State<CheckoutAddressScreen> createState() => _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends State<CheckoutAddressScreen> {
  List<Map<String, dynamic>> addresses = [];
  String? selectedId;
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); loadAddresses(); }

  Future<void> loadAddresses() async {
    final user = db.auth.currentUser;
    if (user == null) { if (mounted) Navigator.pop(context); return; }
    setState(() { loading = true; error = null; });
    try {
      final rows = await db.from('addresses').select()
          .eq('user_id', user.id).order('created_at');
      final result = List<Map<String, dynamic>>.from(rows);
      String? choice = selectedId;
      if (!result.any((a) => a['id'].toString() == choice)) {
        choice = null;
        for (final a in result) {
          if (a['is_default'] == true) { choice = a['id'].toString(); break; }
        }
        if (choice == null && result.isNotEmpty) choice = result.first['id'].toString();
      }
      if (mounted) setState(() { addresses = result; selectedId = choice; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = 'Unable to load delivery addresses: $e'; loading = false; });
    }
  }

  Future<void> addAddress() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressFormPage()));
    if (mounted) await loadAddresses();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('DELIVERY ADDRESS'), centerTitle: true),
    body: loading ? const Center(child: CircularProgressIndicator()) :
      error != null ? Center(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!, textAlign: TextAlign.center),
          TextButton(onPressed: loadAddresses, child: const Text('Retry')),
        ]))) :
      ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Select the recipient and address for this order.',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        for (final a in addresses)
          Card(color: panel, child: RadioListTile<String>(
            value: a['id'].toString(), groupValue: selectedId,
            onChanged: (value) => setState(() => selectedId = value),
            title: Text('${a['full_name']} • ${a['phone']}'),
            subtitle: Text('${a['street']}, ${a['barangay']}, ${a['city']}, ${a['province']} ${a['zip_code']}'),
            secondary: const Icon(Icons.location_on_outlined, color: purple),
          )),
        if (addresses.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No delivery address yet. Add an address to continue.', textAlign: TextAlign.center)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: addAddress, icon: const Icon(Icons.add),
            label: const Text('Add New Address')),
        const SizedBox(height: 16),
        FilledButton(onPressed: selectedId == null ? null : () {
          final selected = addresses.firstWhere((a) => a['id'].toString() == selectedId);
          Navigator.pop(context, Map<String, dynamic>.from(selected));
        }, child: const Text('Continue to Payment')),
      ]),
  );
}
