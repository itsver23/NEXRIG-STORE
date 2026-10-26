import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool editing = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadInformation();
  }

  void loadInformation() {
    final data = db.auth.currentUser?.userMetadata;
    nameController.text = (data?['full_name'] ?? data?['name'] ?? '').toString();
    phoneController.text = (data?['phone'] ?? '').toString();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> saveChanges() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(name)) {
      showMessage('Full name must contain letters and spaces only.');
      return;
    }
    if (!RegExp(r'^09[0-9]{9}$').hasMatch(phone)) {
      showMessage('Phone number must have 11 digits and start with 09.');
      return;
    }
    setState(() => saving = true);
    try {
      await db.auth.updateUser(UserAttributes(data: {
        'full_name': name,
        'phone': phone,
      }));
      if (!mounted) return;
      setState(() => editing = false);
      showMessage('Personal information saved.');
    } catch (e) {
      if (mounted) showMessage('Unable to save: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('PERSONAL INFORMATION')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('MY INFORMATION', style: TextStyle(color: purple, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: nameController,
          readOnly: !editing,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))],
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: phoneController,
          readOnly: !editing,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
          decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: 14),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Email Address (view only)',
            prefixIcon: const Icon(Icons.email_outlined),
            hintText: db.auth.currentUser?.email ?? '',
          ),
        ),
        const SizedBox(height: 22),
        if (!editing)
          FilledButton.icon(
            onPressed: () => setState(() => editing = true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Information'),
          ),
        if (editing) ...[
          FilledButton(onPressed: saving ? null : saveChanges, child: const Text('Save Changes')),
          TextButton(onPressed: saving ? null : () {
            setState(() {
              loadInformation();
              editing = false;
            });
          }, child: const Text('Cancel')),
        ],
      ]),
    );
  }
}
