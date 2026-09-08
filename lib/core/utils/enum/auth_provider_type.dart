/// Sosyal giriş sağlayıcı türleri.
enum AuthProviderType {
  google('google'),
  apple('apple'),
  guest('guest');

  const AuthProviderType(this.value);

  final String value;
}
