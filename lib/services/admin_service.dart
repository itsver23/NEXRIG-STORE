import 'supabase_service.dart';

class AdminService {
  Future<bool> isAdmin() async {
    final user = db.auth.currentUser;
    if (user == null) return false;
    final result = await db.from('admin_users').select('user_id').eq('user_id', user.id).maybeSingle();
    return result != null;
  }
}
