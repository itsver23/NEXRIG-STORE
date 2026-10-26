import '../services/supabase_service.dart';

class AuthService {
  bool get isSignedIn => db.auth.currentUser != null;
  String? get email => db.auth.currentUser?.email;

  Future<bool> register(String email, String password, String name, String phone) async {
    final result = await db.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'phone_number': phone},
    );
    return result.session != null;
  }

  Future<void> login(String email, String password) async {
    await db.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await db.auth.signOut();
  }
}
