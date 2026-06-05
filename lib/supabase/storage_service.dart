import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  const StorageService(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  String? publicVehicleImageUrl(String path) {
    final client = _client;
    if (client == null || path.isEmpty) {
      return null;
    }
    return client.storage.from('vehicle-images').getPublicUrl(path);
  }
}

