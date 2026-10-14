import 'dart:ui';

/// Aktif locale sabitleri. easy_localization `main` / `MyApp` üzerinden bağlanır.
/// (Doküman 8)
final class LocalizationManager {
  LocalizationManager();

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('it'),
    Locale('ru'),
  ];

  static const fallbackLocale = Locale('en');

  static const translationsPath = 'assets/translations';

  /// Uygulamada seçili dil (cihaz dili değil). `MyApp` her build'de günceller;
  /// ağ katmanı `Accept-Language` için okur.
  static Locale current = fallbackLocale;

  /// Desteklenen diller arasında mı?
  static bool isSupported(Locale locale) =>
      supportedLocales.any((l) => l.languageCode == locale.languageCode);
}
