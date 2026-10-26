class AppConfig {
  static const String supabaseUrl = 'https://ojxkwoqxrngtpcuavnpp.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qeGt3b3F4cm5ndHBjdWF2bnBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0OTEyODYsImV4cCI6MjEwODA2NzI4Nn0.LHSt3dvKdxxsm2qUI5Nv9d470pbtNQ8LkI3qNVmZypM';

  static bool get configured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
