# generated/

Bu klasördeki dosyalar **build_runner** ile otomatik üretilir; elle yazılmaz.

```bash
dart run build_runner build --delete-conflicting-outputs
```

Üretilen dosyalar:

| Dosya | Kaynak |
| --- | --- |
| `colors.gen.dart` | `assets/colors/colors.xml` (flutter_gen) |
| `assets.gen.dart` | `assets/` (flutter_gen) |
| `fonts.gen.dart` | `pubspec.yaml` fonts (flutter_gen) |
| `locale_keys.g.dart` | `assets/translations/*.json` (easy_localization) |
