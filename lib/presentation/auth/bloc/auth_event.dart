import 'package:equatable/equatable.dart';
import 'package:fastingapp/data/model/auth/auth_response.dart';
import 'package:fastingapp/data/model/user/user.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Uygulama açılışında mevcut oturumun kontrol edilmesini tetikler.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Başarılı giriş sonrası global oturum durumunu günceller.
final class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn(this.authResponse);

  final AuthResponse authResponse;

  @override
  List<Object?> get props => [authResponse];
}

/// Çıkış tetikler.
final class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();
}

/// Oturum sunucuda kapandı / yenilenemedi (ağ katmanı tetikler): yalnızca yerel
/// temizlik, sunucuya çıkış isteği atılmaz.
final class AuthSessionEnded extends AuthEvent {
  const AuthSessionEnded();
}

/// Kullanıcı bilgisi değişti (ör. onboarding tamamlandı).
final class AuthUserUpdated extends AuthEvent {
  const AuthUserUpdated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}
