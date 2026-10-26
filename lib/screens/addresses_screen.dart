import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Map<String, dynamic>> addresses = [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final user = db.auth.currentUser;
    if (user == null) return;
    setState(() { loading = true; error = null; });
    try {
      final result = await db.from('addresses').select().eq('user_id', user.id).order('created_at');
      if (mounted) setState(() { addresses = List<Map<String, dynamic>>.from(result); loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = '$e'; loading = false; });
    }
  }

  Future<void> deleteAddress(Map<String, dynamic> address) async {
    try {
      await db.from('addresses').delete().eq('id', address['id']);
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> setDefault(Map<String, dynamic> address) async {
    final user = db.auth.currentUser;
    if (user == null) return;
    try {
      await db.from('addresses').update({'is_default': false}).eq('user_id', user.id);
      await db.from('addresses').update({'is_default': true}).eq('id', address['id']);
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> openForm([Map<String, dynamic>? address]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddressFormPage(address: address)));
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(centerTitle: true, title: const Text('MY ADDRESSES')),
    body: loading ? const Center(child: CircularProgressIndicator()) :
      error != null ? Center(child: Padding(padding: const EdgeInsets.all(18), child: Text('Could not load addresses. Run the supplied SQL setup first.\n$error', textAlign: TextAlign.center))) :
      ListView(padding: const EdgeInsets.all(16), children: [
        for (final address in addresses)
          Card(color: panel, child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.location_on, color: purple), const SizedBox(width: 8),
              Expanded(child: Text('${address['label'] ?? 'Home'}${address['is_default'] == true ? '  • Default' : ''}', style: const TextStyle(fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            Text('${address['full_name']} • ${address['phone']}'),
            Text('${address['street']}, ${address['barangay']}, ${address['city']}, ${address['province']} ${address['zip_code']}'),
            Wrap(spacing: 4, children: [
              TextButton(onPressed: () => openForm(address), child: const Text('Edit')),
              TextButton(onPressed: () => deleteAddress(address), child: const Text('Delete')),
              if (address['is_default'] != true) TextButton(onPressed: () => setDefault(address), child: const Text('Set Default')),
            ]),
          ]))),
        if (addresses.isEmpty) const Padding(padding: EdgeInsets.all(18), child: Text('No saved delivery addresses yet.', textAlign: TextAlign.center)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () => openForm(), icon: const Icon(Icons.add), label: const Text('Add New Address')),
      ]),
  );
}

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key, this.address});
  final Map<String, dynamic>? address;
  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final label = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final street = TextEditingController();
  final barangay = TextEditingController();
  final city = TextEditingController();
  final province = TextEditingController();
  final zip = TextEditingController();
  bool isDefault = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    label.text = (a?['label'] ?? 'Home').toString();
    name.text = (a?['full_name'] ?? '').toString();
    phone.text = (a?['phone'] ?? '').toString();
    street.text = (a?['street'] ?? '').toString();
    barangay.text = (a?['barangay'] ?? '').toString();
    city.text = (a?['city'] ?? '').toString();
    province.text = (a?['province'] ?? '').toString();
    zip.text = (a?['zip_code'] ?? '').toString();
    isDefault = a?['is_default'] == true;
  }

  @override
  void dispose() {
    for (final c in [label, name, phone, street, barangay, city, province, zip]) { c.dispose(); }
    super.dispose();
  }

  Future<void> save() async {
    if ([label, name, phone, street, barangay, city, province, zip].any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.'))); return;
    }
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(name.text.trim()) || !RegExp(r'^09[0-9]{9}$').hasMatch(phone.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check name (letters only) and phone (11 digits starting 09).'))); return;
    }
    final user = db.auth.currentUser;
    if (user == null) return;
    setState(() => saving = true);
    try {
      final data = <String, dynamic>{
        'user_id': user.id, 'label': label.text.trim(), 'full_name': name.text.trim(),
        'phone': phone.text.trim(), 'street': street.text.trim(), 'barangay': barangay.text.trim(),
        'city': city.text.trim(), 'province': province.text.trim(), 'zip_code': zip.text.trim(),
        'is_default': isDefault,
      };
      if (isDefault) await db.from('addresses').update({'is_default': false}).eq('user_id', user.id);
      if (widget.address == null) {
        await db.from('addresses').insert(data);
      } else {
        await db.from('addresses').update(data).eq('id', widget.address!['id']);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget field(String title, TextEditingController controller, {TextInputType? keyboard, List<TextInputFormatter>? formatters}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
      controller: controller, keyboardType: keyboard, inputFormatters: formatters,
      decoration: InputDecoration(labelText: title),
    ));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(centerTitle: true, title: Text(widget.address == null ? 'ADD NEW ADDRESS' : 'EDIT ADDRESS')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      field('Label (Home / Office)', label),
      field('Recipient Full Name', name, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))]),
      field('Phone Number', phone, keyboard: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]),
      field('House Number / Street', street),
      field('Barangay', barangay),
      field('City / Municipality', city),
      field('Province', province),
      field('ZIP Code', zip, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]),
      CheckboxListTile(value: isDefault, title: const Text('Set as default delivery address'), onChanged: (v) => setState(() => isDefault = v ?? false)),
      FilledButton(onPressed: saving ? null : save, child: const Text('Save Address')),
    ]),
  );
}
