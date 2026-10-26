import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import 'admin_dashboard_screen.dart';
import '../services/supabase_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isRegister = false;
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirm = false;
  String? authError;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (email.isEmpty || password.isEmpty ||
        (isRegister && (name.isEmpty || phone.isEmpty || confirmController.text.isEmpty))) {
      showMessage('Please fill in all fields.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      showMessage('Please enter a valid email address.');
      return;
    }
    if (isRegister) {
      if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(name)) {
        showMessage('Full name must contain letters and spaces only.');
        return;
      }
      if (!RegExp(r'^09[0-9]{9}$').hasMatch(phone)) {
        showMessage('Phone number must be exactly 11 digits and start with 09.');
        return;
      }
      if (password.length < 6) {
        showMessage('Password must have at least 6 characters.');
        return;
      }
      if (password != confirmController.text) {
        showMessage('Passwords do not match.');
        return;
      }
    }

    setState(() {
      isLoading = true;
      authError = null;
    });
    try {
      if (isRegister) {
        final signedIn = await AuthService().register(email, password, name, phone);
        if (!mounted) return;
        if (!signedIn) {
          showMessage('Account created! Check your email to confirm, then sign in.');
          setState(() => isRegister = false);
          passwordController.clear();
          confirmController.clear();
          return;
        }
      } else {
        await AuthService().login(email, password);
      }
      if (mounted && db.auth.currentUser != null) {
        final admin = await AdminService().isAdmin();
        if (!mounted) return;
        if (admin) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
            (route) => false,
          );
        } else {
          // Preserve existing customer checkout/profile navigation.
          Navigator.pop(context);
        }
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      String message = 'Unable to continue. Please try again.';
      if (error.code == 'invalid_credentials') {
        message = 'Incorrect email or password. Please try again.';
      } else if (error.code == 'email_not_confirmed') {
        message = 'Please verify your email before signing in.';
      } else if (error.code == 'user_already_exists' ||
          error.code == 'email_exists') {
        message = 'This email is already registered. Please sign in.';
      } else if (error.code == 'weak_password') {
        message = 'Please use a stronger password.';
      } else if (error.code == 'over_email_send_rate_limit' ||
          error.code == 'over_request_rate_limit') {
        message = 'Too many attempts. Please try again later.';
      }
      setState(() => authError = message);
    } catch (error) {
      if (mounted) {
        setState(() => authError =
            'Unable to connect. Please check your internet and try again.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool password = false,
    bool confirm = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    final visible = confirm ? showConfirm : showPassword;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        obscureText: password && !visible,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFC69AFF)),
          suffixIcon: password ? IconButton(
            icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                if (confirm) {
                  showConfirm = !showConfirm;
                } else {
                  showPassword = !showPassword;
                }
              });
            },
          ) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9D24FF);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('NEXRIG ACCOUNT'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
          const SizedBox(height: 10),
          const Icon(Icons.memory, color: purple, size: 56),
          const SizedBox(height: 10),
          const Center(
            child: Text('NEXRIG', style: TextStyle(
              fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 3,
            )),
          ),
          const Center(child: Text('S T O R E', style: TextStyle(letterSpacing: 3))),
          const SizedBox(height: 8),
          const Center(child: Text('BUILT FOR GAMERS. POWERED BY YOU.',
            style: TextStyle(color: Color(0xFFC5B7DB), fontSize: 11))),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16192B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF542477)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isRegister ? 'Create Account' : 'Welcome!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(isRegister
                  ? 'Join NEXRIG STORE and start your PC building journey.'
                  : 'Sign in to your NEXRIG STORE account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFBDB7CC))),
                const SizedBox(height: 22),
                if (isRegister) ...[
                  inputField(controller: nameController, label: 'Full Name', icon: Icons.person_outline,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))]),
                  inputField(controller: phoneController, label: 'Phone Number',
                    icon: Icons.phone_outlined, keyboard: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]),
                ],
                inputField(controller: emailController, label: 'Email Address',
                  icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                inputField(controller: passwordController, label: 'Password',
                  icon: Icons.lock_outline, password: true),
                if (isRegister)
                  inputField(controller: confirmController, label: 'Confirm Password',
                    icon: Icons.lock_outline, password: true, confirm: true),
                if (authError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF321923),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF6688)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFFF8FA8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(authError!,
                            style: const TextStyle(color: Color(0xFFFFB1C2))),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isLoading ? 'Please wait...' :
                      (isRegister ? 'Create Account' : 'Sign In')),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: TextButton(
                  onPressed: isLoading ? null : () {
                    setState(() {
                      isRegister = !isRegister;
                      authError = null;
                    });
                  },
                  child: Text(isRegister
                    ? 'Already have an account? Sign In'
                    : "Don't have an account? Register Now"),
                )),
              ],
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
