import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_struggle_advice_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Zorlanıyorum — neden seçimi. İlk açılışta kart seçili gelmez.
final class FastingStruggleView extends StatefulWidget {
  const FastingStruggleView({super.key});

  @override
  State<FastingStruggleView> createState() => _FastingStruggleViewState();
}

class _FastingStruggleViewState extends State<FastingStruggleView> {
  int? _selected;

  static const _options = <_StruggleOption>[
    _StruggleOption(
      image: _StruggleImage.hungry,
      titleKey: 'fasting_struggle.hungry_title',
      bodyKey: 'fasting_struggle.hungry_body',
      reason: FastingStruggleReason.hungry,
    ),
    _StruggleOption(
      image: _StruggleImage.craving,
      titleKey: 'fasting_struggle.craving_title',
      bodyKey: 'fasting_struggle.craving_body',
      reason: FastingStruggleReason.craving,
    ),
    _StruggleOption(
      image: _StruggleImage.energy,
      titleKey: 'fasting_struggle.energy_title',
      bodyKey: 'fasting_struggle.energy_body',
      reason: FastingStruggleReason.energy,
    ),
    _StruggleOption(
      image: _StruggleImage.stressed,
      titleKey: 'fasting_struggle.stressed_title',
      bodyKey: 'fasting_struggle.stressed_body',
      reason: FastingStruggleReason.stressed,
    ),
    _StruggleOption(
      image: _StruggleImage.bored,
      titleKey: 'fasting_struggle.bored_title',
      bodyKey: 'fasting_struggle.bored_body',
      reason: FastingStruggleReason.bored,
    ),
  ];

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
            const _BackRow(),
            const SizedBox(height: 16),
            Center(
              child: Transform.scale(
                scale: 1.2,
                child: appImage(
                  Assets.gifs.mascotWav.path,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'fasting_struggle.title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleTitle,
            ),
            const SizedBox(height: 12),
            Text(
              'fasting_struggle.body'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleBody,
            ),
            const SizedBox(height: 32),
            for (var i = 0; i < _options.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _OptionCard(
                option: _options[i],
                selected: _selected == i,
                onTap: () {
                  setState(() => _selected = i);
                  context.pushNamed(
                    RoutePaths.fastingStruggleAdvice.name,
                    extra: FastingStruggleAdviceArgs(
                      bodyKey: _options[i].bodyKey,
                      reason: _options[i].reason,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _StruggleImage { hungry, craving, energy, stressed, bored }

@immutable
final class _StruggleOption {
  const _StruggleOption({
    required this.image,
    required this.titleKey,
    required this.bodyKey,
    required this.reason,
  });

  final _StruggleImage image;
  final String titleKey;
  final String bodyKey;
  final FastingStruggleReason reason;

  AppImageAsset get asset => switch (image) {
    _StruggleImage.hungry => AppImages.hungry,
    _StruggleImage.craving => AppImages.cravling,
    _StruggleImage.energy => AppImages.lowEnergiy,
    _StruggleImage.stressed => AppImages.stressed,
    _StruggleImage.bored => AppImages.bored,
  };
}

final class _BackRow extends StatelessWidget {
  const _BackRow();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => context.pop(),
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

final class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _StruggleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? ColorName.colorOptionSelected
        : ColorName.colorPlanArcTrack;
    return Material(
      color: selected
          ? ColorName.colorOptionSelected.withValues(alpha: 0.08)
          : ColorName.colorWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                option.asset.image(width: 40, height: 40, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.titleKey.tr(),
                        style: AppTextStyles.fastingStruggleOptionTitle,
                      ),
                      Text(
                        option.bodyKey.tr(),
                        style: AppTextStyles.fastingStruggleOptionBody,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
