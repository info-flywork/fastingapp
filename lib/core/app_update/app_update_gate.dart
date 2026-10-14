import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/router/app_router.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/constants/store_links.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

/// Sürüm kontrolü (`GET /app/config` → `updateRequired` / `updateAvailable`;
/// istek başlıkları `X-Platform` + `X-App-Version`). Zorunluysa kapatılamaz
/// "Güncelle" ekranı; değilse oturumda bir kez önerilir. Sunucu eski
/// sürüme herhangi bir istekte `426 APP_UPDATE_REQUIRED` dönerse de açılır.
/// Önceden bu bilgiler okunmuyor, eski sürümler hiç engellenemiyordu.
abstract final class AppUpdateGate {
  static var _checked = false;
  static var _optionalShown = false;
  static var _blocking = false;

  /// Açılışta (ana kabuk) bir kez.
  static Future<void> check() async {
    if (_checked) return;
    _checked = true;
    try {
      final config = await getIt<NetworkManager>().send<_UpdateConfig>(
        path: '/app/config',
        method: RequestType.get,
        parserModel: _UpdateConfig.fromJson,
      );
      if (config == null) return;
      if (config.required) {
        _showBlocking();
      } else if (config.available && !_optionalShown) {
        _optionalShown = true;
        _show(blocking: false);
      }
    } on Object {
      _checked = false;
    }
  }

  static void _showBlocking() {
    if (_blocking) return;
    _blocking = true;
    _show(blocking: true);
  }

  static void _show({required bool blocking}) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      _blocking = false;
      return;
    }
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: !blocking,
        builder: (_) => PopScope(
          canPop: !blocking,
          child: _UpdateDialog(blocking: blocking),
        ),
      ),
    );
  }

  static Future<void> openStore() => InAppReview.instance.openStoreListing(
    appStoreId: StoreLinks.iosAppId.isEmpty ? null : StoreLinks.iosAppId,
  );
}

/// Herhangi bir istekte 426 → zorunlu güncelleme ekranı.
final class AppUpdateInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 426) AppUpdateGate._showBlocking();
    handler.next(err);
  }
}

final class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({required this.blocking});

  final bool blocking;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (blocking ? 'app_update.required_title' : 'app_update.title')
                    .tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.fastingEndTitle,
              ),
              const SizedBox(height: 12),
              Text(
                (blocking ? 'app_update.required_body' : 'app_update.body')
                    .tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.fastingEndBody,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'app_update.update'.tr(),
                showIcon: false,
                decoration: AppButtonDecoration.homeJoin(),
                onPressed: () => unawaited(AppUpdateGate.openStore()),
              ),
              if (!blocking)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'app_update.later'.tr(),
                    style: AppTextStyles.fastingEndBody,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _UpdateConfig implements BaseModel<_UpdateConfig> {
  const _UpdateConfig({this.required = false, this.available = false});

  factory _UpdateConfig.fromJson(Map<String, dynamic> json) => _UpdateConfig(
    required: json['updateRequired'] as bool? ?? false,
    available: json['updateAvailable'] as bool? ?? false,
  );

  final bool required;
  final bool available;

  @override
  _UpdateConfig fromJson(Map<String, dynamic> json) =>
      _UpdateConfig.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
