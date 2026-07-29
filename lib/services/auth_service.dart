import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../config/supabase_config.dart';
import 'cache_service.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;


  static const String _avatarBucket = 'avatars';

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;


  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? studentId,
    String? department,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'student_id': studentId,
          'department': department,
        },
      );

      if (response.user != null) {

        await _client.from(AppConstants.profilesTable).upsert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'student_id': studentId,
          'department': department,
          'role': 'student',
          'created_at': DateTime.now().toIso8601String(),
        });
        return AuthResult(success: true);
      }
      return AuthResult(success: false, message: 'Sign up failed');
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }


  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }


  Future<AuthResult> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.unicompanion://login-callback',
      );
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }


  Future<void> signOut() async {

    await CacheService.instance.clearUserData();
    await _client.auth.signOut();
  }


  Future<UserProfile?> getCurrentProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final data = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromMap(data);
    } catch (e) {
      return null;
    }
  }


  Future<bool> updateProfile(UserProfile profile) async {
    try {
      await _client
          .from(AppConstants.profilesTable)
          .update(profile.toMap())
          .eq('id', profile.id);
      return true;
    } catch (e) {
      return false;
    }
  }


  Future<String?> uploadAvatar(Uint8List bytes, String fileExt) async {
    final user = currentUser;
    if (user == null) return null;

    final ext = fileExt.toLowerCase();
    final contentType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
        ? 'image/webp'
        : 'image/jpeg';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/avatar_$stamp.$ext';

    await _client.storage.from(_avatarBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: contentType),
    );

    return _client.storage.from(_avatarBucket).getPublicUrl(path);
  }


  Future<AuthResult> updateEmail(String newEmail) async {
    try {
      await _client.auth.updateUser(UserAttributes(email: newEmail));
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }


  Future<AuthResult> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.unicompanion://login-callback',
      );
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }


  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }
}

class AuthResult {
  final bool success;
  final String? message;
  AuthResult({required this.success, this.message});
}