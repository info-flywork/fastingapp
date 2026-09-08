import 'package:equatable/equatable.dart';
import 'package:fastingapp/data/model/auth/auth_response.dart';

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
