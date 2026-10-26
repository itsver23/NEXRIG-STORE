import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexrigApp());
}

class NexrigApp extends StatelessWidget {
  const NexrigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXRIG STORE',
      theme: nexrigTheme,
      home: const NexrigLoadingScreen(),
    );
  }
}

class NexrigLoadingScreen extends StatefulWidget {
  const NexrigLoadingScreen({super.key});

  @override
  State<NexrigLoadingScreen> createState() => _NexrigLoadingScreenState();
}

class _NexrigLoadingScreenState extends State<NexrigLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Color purple = Color(0xFF9D4EDD);
  static const Color background = Color(0xFF08070D);

  bool _supabaseReady = false;
  bool _supabaseFailed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tryNavigate();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.forward(from: 0);
      _initializeSupabase();
    });
  }

  Future<void> _initializeSupabase() async {
    if (!AppConfig.configured) {
      _supabaseFailed = true;
    } else {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        );
      } catch (e) {
        debugPrint('Supabase initialization failed: $e');
        _supabaseFailed = true;
      }
    }

    if (!mounted) return;
    _supabaseReady = true;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!mounted ||
        _navigated ||
        !_supabaseReady ||
        !_controller.isCompleted) {
      return;
    }

    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            _supabaseFailed ? const SetupPage() : const StorePage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final percent =
                    (_controller.value * 100).round().clamp(0, 100);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: purple,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: purple.withValues(alpha: 0.28),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 76,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'NEXRIG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                    const Text(
                      'STORE',
                      style: TextStyle(
                        color: purple,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'BUILD BEYOND LIMITS',
                      style: TextStyle(
                        color: Color(0xFF9A96A6),
                        fontSize: 11,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 75),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'INITIALIZING NEXRIG...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            color: purple,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 9,
                        backgroundColor: const Color(0xFF24202E),
                        valueColor: const AlwaysStoppedAnimation<Color>(purple),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'POWERING UP YOUR SETUP',
                      style: TextStyle(
                        color: Color(0xFF696574),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
