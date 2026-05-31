import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
  });

  final String url;
  final String anonKey;

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

final supabaseConfigProvider = Provider<SupabaseConfig>((ref) {
  return SupabaseConfig(
    url: dotenv.maybeGet('SUPABASE_URL') ?? '',
    anonKey: dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '',
  );
});

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final config = ref.watch(supabaseConfigProvider);
  if (!config.isConfigured) {
    return null;
  }
  return SupabaseClient(config.url, config.anonKey);
});
