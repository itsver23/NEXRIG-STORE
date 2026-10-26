import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import 'account_screen.dart';
import 'addresses_screen.dart';
import 'account_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onLoggedOut});
  final VoidCallback onLoggedOut;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> openPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Future<void> logout() async {
    await AuthService().logout();
    if (mounted) widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = db.auth.currentUser;
    if (user == null) {
      return Center(child: ElevatedButton(
        onPressed: () => openPage(const AccountPage()),
        child: const Text('Sign In / Register'),
      ));
    }
    final name = (user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '').toString();
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Center(child: Text('MY ACCOUNT', style: TextStyle(color: purple, fontWeight: FontWeight.bold, letterSpacing: 2))),
      const SizedBox(height: 18),
      Card(color: panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF62318B))),
        child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
          const CircleAvatar(radius: 32, backgroundColor: purple, child: Icon(Icons.person, color: Colors.white, size: 36)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty ? 'NEXRIG Member' : name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Text(user.email ?? '', style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis),
            const Text('NEXRIG Member', style: TextStyle(color: purple, fontSize: 12)),
          ])),
        ]))),
      const SizedBox(height: 24),
      const Text('ACCOUNT MENU', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Card(color: panel, child: ListTile(
        leading: const Icon(Icons.location_on_outlined, color: purple),
        title: const Text('My Addresses'), subtitle: const Text('Manage delivery addresses'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openPage(const AddressesScreen()),
      )),
      Card(color: panel, child: ListTile(
        leading: const Icon(Icons.settings_outlined, color: purple),
        title: const Text('Account Settings'), subtitle: const Text('Personal information and password'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openPage(const AccountSettingsScreen()),
      )),
      const SizedBox(height: 20),
      Card(color: const Color(0xFF281624), child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.pinkAccent),
        title: const Text('Log Out', style: TextStyle(color: Colors.pinkAccent)),
        subtitle: const Text('Sign out from your account'),
        onTap: logout,
      )),
    ]);
  }
}
