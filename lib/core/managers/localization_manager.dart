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
  ];

  static const fallbackLocale = Locale('en');

  static const translationsPath = 'assets/translations';

  /// Desteklenen diller arasında mı?
  static bool isSupported(Locale locale) =>
      supportedLocales.any((l) => l.languageCode == locale.languageCode);
}
