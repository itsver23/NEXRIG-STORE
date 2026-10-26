import 'package:flutter/material.dart';

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('NEXRIG STORE\n\nSupabase is not configured yet.\n\nRun Flutter with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...\n\nSee SETUP_GUIDE.md', textAlign: TextAlign.center),
    )),
  );
}

