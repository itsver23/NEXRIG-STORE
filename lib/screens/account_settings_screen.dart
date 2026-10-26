import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'personal_information_screen.dart';
import 'change_password_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('ACCOUNT SETTINGS')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('MANAGE ACCOUNT', style: TextStyle(color: purple, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(color: panel, child: ListTile(
          leading: const Icon(Icons.person_outline, color: purple),
          title: const Text('Personal Information'),
          subtitle: const Text('View or edit your name and phone number'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInformationScreen())),
        )),
        Card(color: panel, child: ListTile(
          leading: const Icon(Icons.lock_outline, color: purple),
          title: const Text('Change Password'),
          subtitle: const Text('Update your account password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
        )),
      ]),
    );
  }
}
