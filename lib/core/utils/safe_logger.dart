// ignore_for_file: avoid_print

class SafeLogger {
  const SafeLogger._();

  static String mask(String input) {
    var result = input;

    // Mask JWT tokens (starting with eyJ)
    final jwtRegex =
        RegExp(r'\beyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]*\b');
    result = result.replaceAllMapped(jwtRegex, (match) {
      final token = match.group(0)!;
      if (token.length <= 10) return '[JWT_TOKEN]';
      return '${token.substring(0, 5)}...[REDACTED]';
    });

    // Mask Google Client IDs
    final googleClientIdRegex =
        RegExp(r'\b[A-Za-z0-9-_]+\.apps\.googleusercontent\.com\b');
    result = result.replaceAllMapped(googleClientIdRegex, (match) {
      final clientId = match.group(0)!;
      const suffix = '.apps.googleusercontent.com';
      final prefix = clientId.substring(0, clientId.length - suffix.length);
      if (prefix.length <= 6) return '***$suffix';
      return '${prefix.substring(0, 6)}...${suffix.substring(1)}';
    });

    // Mask token variables in query/text
    final tokenValueRegex =
        RegExp(r'\b(idToken|accessToken|refreshToken)\b', caseSensitive: false);
    result = result.replaceAllMapped(tokenValueRegex, (match) {
      return '[REDACTED_TOKEN]';
    });

    return result;
  }

  static void log(String message) {
    // Under test, this can print masked output
    print(mask(message));
  }
}
