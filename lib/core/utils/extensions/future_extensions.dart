import 'dart:async';

import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';

/// Uzun süren async işlemlerde loading dialog gösteren extension.
///
/// Yalnızca view veya mixin'den çağrılır; repository/BLoC içinden ASLA.
/// (Doküman 9.6)
extension FutureLoadingExtension<T> on Future<T> {
  /// [showAfter] verilirse iş o süreden önce biterse dialog hiç açılmaz
  /// (kısa işlerde ekran yanıp sönmez). Çift dokunmaya açık kalan bu kısa
  /// aralık yalnızca tekrarı zararsız işlerde kullanılmalı.
  Future<T> withLoading(BuildContext context, {Duration? showAfter}) async {
    var shown = false;
    void show() {
      if (!context.mounted) return;
      shown = true;
      unawaited(
        AppDialogs.instance.showNormalDialog<void>(
          context: context,
          barrierDismissible: false,
          child: const PopScope(canPop: false, child: LoadingDialog()),
        ),
      );
    }

    final timer = showAfter == null ? null : Timer(showAfter, show);
    if (timer == null) show();

    try {
      return await this;
    } finally {
      timer?.cancel();
      if (shown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}
