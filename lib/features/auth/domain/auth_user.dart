import '../../../shared/models/fuel_arena_models.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    this.provider = 'google',
    this.profile,
  });

  final String id;
  final String email;
  final String displayName;
  final String avatarUrl;
  final String provider;
  final UserProfile? profile;

  factory AuthUser.fromProfile(UserProfile profile) {
    return AuthUser(
      id: profile.id,
      email: profile.email,
      displayName: profile.nickname,
      avatarUrl: profile.avatarUrl,
      provider: profile.authProvider,
      profile: profile,
    );
  }
}
