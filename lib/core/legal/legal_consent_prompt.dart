import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:flutter/widgets.dart';

/// Şartlar / gizlilik sürümü değişince yeniden onay (`requiredConsents`).
/// Uygulama açılışında bir kez sorulur; "Sonra" denirse bir sonraki
/// açılışta tekrar. Önceden alan hiç okunmuyordu.
abstract final class LegalConsentPrompt {
  static var _checked = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_checked) return;
    _checked = true;
    final repo = getIt<UserRepository>();
    final List<String> required;
    try {
      required = await repo.requiredConsents();
    } on Object {
      _checked = false;
      return;
    }
    if (required.isEmpty || !context.mounted) return;
    final accepted = await AppDialogs.instance.showLegalUpdate(context);
    if (accepted != true) return;
    try {
      await repo.acceptConsents(required);
    } on Object catch (e) {
      _checked = false;
      if (context.mounted) AppSnackbar.showError(context, e);
    }
  }

  /// Çıkış / hesap değişimi: yeni kullanıcı için tekrar kontrol edilsin.
  static void reset() => _checked = false;
}
