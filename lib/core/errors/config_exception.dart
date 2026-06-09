class ConfigException implements Exception {
  const ConfigException({
    required this.userMessage,
    this.developerMessage = '',
    this.missingKeys = const [],
  });

  final String userMessage;
  final String developerMessage;
  final List<String> missingKeys;

  @override
  String toString() {
    if (developerMessage.isEmpty) {
      return userMessage;
    }
    return developerMessage;
  }
}
