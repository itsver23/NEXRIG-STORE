import 'package:supabase_flutter/supabase_flutter.dart';

// Shared client, following the classroom service pattern.
SupabaseClient get db => Supabase.instance.client;
String money(num value) => '₱${value.toStringAsFixed(2)}';
