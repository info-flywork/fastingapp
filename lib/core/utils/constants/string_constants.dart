/// Sabit string değerleri (baseUrl vb.).
final class StringConstants {
  const StringConstants._();

  /// Backend API kök adresi (`/v1` dahil).
  /// `--dart-define=API_BASE_URL=…` verilirse o kullanılır.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'https://mochifast.fly-work.com/v1';
  }
}
