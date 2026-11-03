import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/domain/chat/chat_repository.dart';
import 'package:flutter/material.dart';

/// AI işleme rızası (`aiProcessing`): sohbet ve fotoğraf analizi öncesi.
/// Sessiz grant yok — kullanıcı onaylamadan sunucuya yazılmaz.
abstract final class AiConsent {
  static bool? _cachedGranted;

  /// Yerel önbellek (oturum içi); çıkışta [clear] çağır.
  static void clear() => _cachedGranted = null;

  /// Sohbet açılırken rızayı arka planda ısıt — ilk öneri tıkında ağ beklemesin.
  static Future<void> warmUp() async {
    if (_cachedGranted == true) return;
    try {
      if (await getIt<ChatRepository>().hasAiProcessingConsent()) {
        _cachedGranted = true;
      }
    } on Object {
      // ensure sırasında yeniden denenecek.
    }
  }

  /// Sunucu rızayı tanımıyor (`CONSENT_REQUIRED`, ör. başka cihazda geri
  /// çekildi): önbellek bırakılır, bir sonraki denemede yeniden sorulur.
  static void onError(Object error) {
    if (error is NetworkException && error.code == 'CONSENT_REQUIRED') {
      clear();
    }
  }

  /// Rıza yoksa diyalog gösterir; onaylanırsa `POST /user/consents`.
  /// `true` → devam edilebilir; `false` → kullanıcı vazgeçti / hata.
  static Future<bool> ensure(BuildContext context) async {
    if (_cachedGranted ?? false) return true;

    final repo = getIt<ChatRepository>();
    try {
      if (await repo.hasAiProcessingConsent()) {
        _cachedGranted = true;
        return true;
      }
    } on Object {
      // Liste okunamazsa yine de sor (sunucu CONSENT_REQUIRED dönebilir).
    }

    if (!context.mounted) return false;
    final ok = await AppDialogs.instance.showAiProcessingConsent(context);
    if (ok != true) return false;

    try {
      await repo.grantAiProcessingConsent();
      _cachedGranted = true;
      return true;
    } on Object catch (e) {
      // Önceden sessizdi: kullanıcı onayladı ama hiçbir şey olmuyordu.
      if (context.mounted) AppSnackbar.showError(context, e);
      return false;
    }
  }
}
