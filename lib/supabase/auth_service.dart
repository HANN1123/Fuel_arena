import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  const AuthService(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase 환경변수가 설정되지 않았습니다.');
    }
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
