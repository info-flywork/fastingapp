import 'dart:async';

import 'package:fastingapp/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';

/// Uzun süren async işlemlerde loading dialog gösteren extension.
///
/// Yalnızca view veya mixin'den çağrılır; repository/BLoC içinden ASLA.
/// (Doküman 9.6)
extension FutureLoadingExtension<T> on Future<T> {
  Future<T> withLoading(BuildContext context) async {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: LoadingDialog(),
        ),
      ),
    );

    try {
      return await this;
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}
