import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Zorlanma nedeni. Sonraki sayfadaki öneri kartlarını belirler.
enum FastingStruggleReason { hungry, craving, energy, stressed, bored }

/// Mochi öneri sayfasına giden seçim.
@immutable
final class FastingStruggleAdviceArgs {
  const FastingStruggleAdviceArgs({
    required this.bodyKey,
    required this.reason,
  });

  final String bodyKey;
  final FastingStruggleReason reason;
}

/// Seçilen zorlanma nedeninden sonra açılan Mochi önerileri.
final class FastingStruggleAdviceView extends StatefulWidget {
  const FastingStruggleAdviceView({required this.args, super.key});

  final FastingStruggleAdviceArgs args;

  @override
  State<FastingStruggleAdviceView> createState() =>
      _FastingStruggleAdviceViewState();
}

class _FastingStruggleAdviceViewState extends State<FastingStruggleAdviceView> {
  int? _selected;

  static const _hydration = _Tip(
    image: _TipImage.hydration,
    titleKey: 'fasting_struggle.hydration_title',
    bodyKey: 'fasting_struggle.hydration_body',
  );
  static const _walk = _Tip(
    image: _TipImage.walk,
    titleKey: 'fasting_struggle.walk_title',
    bodyKey: 'fasting_struggle.walk_body',
  );
  static const _breathe = _Tip(
    image: _TipImage.breathe,
    titleKey: 'fasting_struggle.breathe_title',
    bodyKey: 'fasting_struggle.breathe_body',
  );

  List<_Tip> get _tips => switch (widget.args.reason) {
    FastingStruggleReason.hungry => const [_hydration, _walk],
    FastingStruggleReason.craving => const [_breathe],
    FastingStruggleReason.energy => const [_walk],
    FastingStruggleReason.stressed => const [_hydration, _breathe],
    FastingStruggleReason.bored => const [_hydration, _walk, _breathe],
  };

  void _backToTimer(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            Text(
              'fasting_struggle.says'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleTitle,
            ),
            const SizedBox(height: 12),
            Text(
              widget.args.bodyKey.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleBody,
            ),
            const SizedBox(height: 32),
            for (var i = 0; i < _tips.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _TipCard(
                tip: _tips[i],
                selected: _selected == i,
                onTap: () {
                  setState(() => _selected = i);
                  final extra = widget.args.bodyKey;
                  if (_tips[i].image == _TipImage.hydration) {
                    context.pushNamed(
                      RoutePaths.fastingSipChallenge.name,
                      extra: extra,
                    );
                    return;
                  }
                  if (_tips[i].image == _TipImage.walk) {
                    context.pushNamed(
                      RoutePaths.fastingQuickWalk.name,
                      extra: extra,
                    );
                    return;
                  }
                  if (_tips[i].image == _TipImage.breathe) {
                    context.pushNamed(
                      RoutePaths.fastingBreath.name,
                      extra: extra,
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _TipImage { hydration, walk, breathe }

@immutable
final class _Tip {
  const _Tip({
    required this.image,
    required this.titleKey,
    required this.bodyKey,
  });

  final _TipImage image;
  final String titleKey;
  final String bodyKey;

  AppImageAsset get asset => switch (image) {
    _TipImage.hydration => AppImages.blob,
    _TipImage.walk => AppImages.quickWalk,
    _TipImage.breathe => AppImages.breathe,
  };
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
                'notifications.back'.tr(),
                style: AppTextStyles.fastingStruggleBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.tip,
    required this.selected,
    required this.onTap,
  });

  final _Tip tip;
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
                tip.asset.image(width: 40, height: 40, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.titleKey.tr(),
                        style: AppTextStyles.fastingStruggleOptionTitle,
                      ),
                      Text(
                        tip.bodyKey.tr(),
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
