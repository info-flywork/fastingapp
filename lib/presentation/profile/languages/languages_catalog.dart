import 'package:fastingapp/generated/assets.gen.dart';
import 'package:flutter/material.dart';

/// Dil seçenek kataloğu: yalnızca çevirisi olan diller (backend
/// `SUPPORTED_LOCALES` ile aynı).
@immutable
final class AppLanguageOption {
  const AppLanguageOption({
    required this.code,
    required this.nameKey,
    required this.flag,
    required this.locale,
  });

  final String code;
  final String nameKey;
  final SvgGenImage flag;
  final Locale locale;
}

abstract final class LanguagesCatalog {
  static final List<AppLanguageOption> options = [
    AppLanguageOption(
      code: 'en',
      nameKey: 'languages.english',
      flag: Assets.flags.icEnglish,
      locale: const Locale('en'),
    ),
    AppLanguageOption(
      code: 'tr',
      nameKey: 'languages.turkish',
      flag: Assets.flags.icTurkey,
      locale: const Locale('tr'),
    ),
    AppLanguageOption(
      code: 'fr',
      nameKey: 'languages.french',
      flag: Assets.flags.icFrench,
      locale: const Locale('fr'),
    ),
    AppLanguageOption(
      code: 'it',
      nameKey: 'languages.italian',
      flag: Assets.flags.icItaly,
      locale: const Locale('it'),
    ),
    AppLanguageOption(
      code: 'de',
      nameKey: 'languages.german',
      flag: Assets.flags.icGermany,
      locale: const Locale('de'),
    ),
    AppLanguageOption(
      code: 'es',
      nameKey: 'languages.spanish',
      flag: Assets.flags.icSpanish,
      locale: const Locale('es'),
    ),
    AppLanguageOption(
      code: 'pt',
      nameKey: 'languages.portuguese',
      flag: Assets.flags.icPortugal,
      locale: const Locale('pt'),
    ),
    AppLanguageOption(
      code: 'ko',
      nameKey: 'languages.korean',
      flag: Assets.flags.icKorean,
      locale: const Locale('ko'),
    ),
    AppLanguageOption(
      code: 'hi',
      nameKey: 'languages.indian',
      flag: Assets.flags.icIndia,
      locale: const Locale('hi'),
    ),
    AppLanguageOption(
      code: 'zh',
      nameKey: 'languages.chinese',
      flag: Assets.flags.icChina,
      locale: const Locale('zh'),
    ),
    AppLanguageOption(
      code: 'ru',
      nameKey: 'languages.russian',
      flag: Assets.flags.icRussian,
      locale: const Locale('ru'),
    ),
    AppLanguageOption(
      code: 'ja',
      nameKey: 'languages.japanese',
      flag: Assets.flags.icJapanne,
      locale: const Locale('ja'),
    ),
  ];

  static AppLanguageOption? byCode(String code) {
    for (final option in options) {
      if (option.code == code) return option;
    }
    return null;
  }
}
