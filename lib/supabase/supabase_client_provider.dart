import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/providers/repository_providers.dart';
import 'auth_service.dart';
import 'realtime_service.dart';
import 'storage_service.dart';
import 'supabase_config.dart';

final supabaseRuntimeConfigProvider = Provider<SupabaseRuntimeConfig>((ref) {
  return SupabaseRuntimeConfig.fromAppConfig(ref.watch(appConfigProvider));
});

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final config = ref.watch(supabaseRuntimeConfigProvider);
  if (!config.isConfigured) {
    return null;
  }
  try {
    return Supabase.instance.client;
  } catch (_) {
    return SupabaseClient(config.url, config.anonKey);
  }
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(ref.watch(supabaseClientProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});
