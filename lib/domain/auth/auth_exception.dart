/// Auth iş kuralı hataları.
class AuthException implements Exception {
  const AuthException(this.message);

  factory AuthException.emptyResponse() =>
      const AuthException('Sunucudan boş yanıt alındı.');

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Hesabın silme talebi beklemede (backend `409 ACCOUNT_PENDING_DELETION`).
/// Kullanıcı onaylarsa [restore] aynı girişi hesabı geri açarak tekrarlar.
final class AccountPendingDeletionException<T> extends AuthException {
  const AccountPendingDeletionException(this.scheduledFor, this.restore)
    : super('Hesap silinmek üzere.');

  final DateTime scheduledFor;
  final Future<T> Function() restore;
}

/// Kullanıcı giriş penceresini kapattı; hata gösterilmez.
final class AuthCancelledException extends AuthException {
  const AuthCancelledException() : super('Giriş iptal edildi.');
}
