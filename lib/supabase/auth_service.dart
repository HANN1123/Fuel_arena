import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  const AuthService(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Future<bool> signInWithGoogleOAuth({String? redirectTo}) {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase 환경변수가 설정되지 않았습니다.');
    }
    return client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  User? get currentUser => _client?.auth.currentUser;

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }
}
