import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_highlight_view.dart';
import 'package:fastingapp/core/widgets/onboarding/onboarding_info_chip.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// About you sonrası gizlilik highlight ekranı + sağlık verisi açık rızası
/// (işaretlenmeden devam edilmez; sunucu `consents.healthData: true` ister).
final class PrivacyHighlightView extends StatefulWidget {
  const PrivacyHighlightView({super.key});

  @override
  State<PrivacyHighlightView> createState() => _PrivacyHighlightViewState();
}

class _PrivacyHighlightViewState extends State<PrivacyHighlightView> {
  OnboardingDraft get _draft => getIt<OnboardingDraft>();

  @override
  Widget build(BuildContext context) {
    final consent = _draft.healthDataConsent;
    return OnboardingHighlightView(
      mediaPath: Assets.gifs.mascotHearts.path,
      title: 'onboarding.lovely_to_meet_you'.tr(),
      subtitle: Text(
        'onboarding.privacy_highlight_subtitle'.tr(),
        textAlign: TextAlign.center,
      ),
      middle: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingInfoChip(
            leading: const Text('🔒', style: TextStyle(fontSize: 16)),
            label: 'onboarding.privacy_chip'.tr(),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _draft.healthDataConsent = !consent),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: consent,
                    activeColor: ColorName.colorOptionSelected,
                    onChanged: (v) =>
                        setState(() => _draft.healthDataConsent = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'onboarding.health_consent'.tr(),
                        style: AppTextStyles.footerHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      buttonLabel: 'onboarding.lets_keep_going'.tr(),
      onContinue: consent
          ? () => context.push(RoutePaths.startingPoint.path)
          : null,
    );
  }
}
