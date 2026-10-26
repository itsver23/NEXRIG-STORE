import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> updatePassword() async {
    if (passwordController.text.length < 8) {
      showMessage('Password must have at least 8 characters.');
      return;
    }
    if (passwordController.text != confirmController.text) {
      showMessage('Passwords do not match.');
      return;
    }
    setState(() => saving = true);
    try {
      await db.auth.updateUser(UserAttributes(password: passwordController.text));
      passwordController.clear();
      confirmController.clear();
      if (mounted) showMessage('Password updated successfully.');
    } catch (e) {
      if (mounted) showMessage('Unable to update password: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('CHANGE PASSWORD')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('ACCOUNT SECURITY', style: TextStyle(color: purple, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: confirmController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: saving ? null : updatePassword, child: const Text('Update Password')),
        const SizedBox(height: 12),
        const Text('Supabase may require additional verification for password changes.', style: TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    );
  }
}
