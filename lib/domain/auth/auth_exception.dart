/// Auth iş kuralı hataları.
final class AuthException implements Exception {
  const AuthException(this.message);

  factory AuthException.emptyResponse() =>
      const AuthException('Sunucudan boş yanıt alındı.');

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
