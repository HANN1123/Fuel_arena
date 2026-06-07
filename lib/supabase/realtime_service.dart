import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  const RealtimeService(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  RealtimeChannel? rankingChannel(String userId) {
    final client = _client;
    if (client == null) {
      return null;
    }
    return client.channel('rankings:user:$userId');
  }
}
