import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/fasting_finish_flow.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Aktivite bitince: devam, başka aktivite ya da orucu bitir.
final class FastingFeelingBetterView extends StatelessWidget {
  const FastingFeelingBetterView({super.key});

  void _backToTimer(BuildContext context) {
    context.goNamed(RoutePaths.fasting.name);
  }

  Future<void> _endFast(BuildContext context) async {
    final confirmed = await AppDialogs.instance.showEndFast(context);
    if (confirmed != true || !context.mounted) return;
    // Zamanlayıcıya dön, üstünde bitirme ekranı (kayıt orada).
    context.goNamed(RoutePaths.fasting.name);
    await FastingFinishFlow.open();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: ColorName.colorWhite,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 24),
          children: [
            _BackRow(onTap: () => _backToTimer(context)),
            const SizedBox(height: 24),
            Center(
              child: Transform.scale(
                scale: 1.2,
                child: appImage(
                  Assets.gifs.mascotHearts.path,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'fasting_struggle.feeling_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleTitle,
            ),
            const SizedBox(height: 12),
            Text(
              'fasting_struggle.feeling_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleBody,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'fasting_struggle.feeling_keep'.tr(),
              onPressed: () => _backToTimer(context),
              showIcon: false,
              decoration: AppButtonDecoration.fastingStart(),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'fasting_struggle.feeling_another'.tr(),
              onPressed: () => context.pop(),
              showIcon: false,
              decoration: AppButtonDecoration.fastingAnother(),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'fasting_struggle.feeling_end'.tr(),
              onPressed: () => _endFast(context),
              showIcon: false,
              decoration: AppButtonDecoration.fastingStruggle(),
            ),
          ],
        ),
      ),
    );
  }
}

final class _BackRow extends StatelessWidget {
  const _BackRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.icons.solarArrowLeftLinear1.image(
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Text(
                'fasting_struggle.back'.tr(),
                style: AppTextStyles.fastingStruggleBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
