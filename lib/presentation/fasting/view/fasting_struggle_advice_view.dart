import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/domain/content/content_repository.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Zorlanma nedeni. Sonraki sayfadaki öneri kartlarını belirler.
enum FastingStruggleReason { hungry, craving, energy, stressed, bored }

/// Mochi öneri sayfasına giden seçim.
@immutable
final class FastingStruggleAdviceArgs {
  const FastingStruggleAdviceArgs({
    required this.bodyText,
    required this.reason,
  });

  final String bodyText;
  final FastingStruggleReason reason;
}

/// Seçilen zorlanma nedeninden sonra açılan Mochi önerileri.
/// Metinler `GET /catalog/struggle`; yüklenemezse yerel çeviri.
final class FastingStruggleAdviceView extends StatefulWidget {
  const FastingStruggleAdviceView({required this.args, super.key});

  final FastingStruggleAdviceArgs args;

  @override
  State<FastingStruggleAdviceView> createState() =>
      _FastingStruggleAdviceViewState();
}

class _FastingStruggleAdviceViewState extends State<FastingStruggleAdviceView> {
  int? _selected;
  List<_Tip> _tips = const [];

  @override
  void initState() {
    super.initState();
    _tips = _localTips(widget.args.reason);
    unawaited(_loadCatalogTips());
  }

  Future<void> _loadCatalogTips() async {
    try {
      final catalog = await getIt<ContentRepository>().struggle();
      final reason = catalog.reason(widget.args.reason.name);
      if (reason == null || reason.tips.isEmpty) return;
      final tips = <_Tip>[
        for (final code in reason.tips)
          if (_tipFromCatalog(catalog, code) case final tip?) tip,
      ];
      if (!mounted || tips.isEmpty) return;
      setState(() => _tips = tips);
    } on Object {
      // Yerel ipuçları kalır.
    }
  }

  static List<_Tip> _localTips(FastingStruggleReason reason) {
    _Tip tip(_TipImage image) => _Tip(
      image: image,
      code: image.name,
      title: _localTitleKey(image.name).tr(),
      body: _localBodyKey(image.name).tr(),
    );
    return switch (reason) {
      FastingStruggleReason.hungry => [
        tip(_TipImage.hydration),
        tip(_TipImage.walk),
      ],
      FastingStruggleReason.craving => [tip(_TipImage.breathe)],
      FastingStruggleReason.energy => [tip(_TipImage.walk)],
      FastingStruggleReason.stressed => [
        tip(_TipImage.hydration),
        tip(_TipImage.breathe),
      ],
      FastingStruggleReason.bored => [
        tip(_TipImage.hydration),
        tip(_TipImage.walk),
        tip(_TipImage.breathe),
      ],
    };
  }

  static _TipImage? _tipImage(String code) => switch (code) {
    'hydration' => _TipImage.hydration,
    'walk' => _TipImage.walk,
    'breathe' => _TipImage.breathe,
    _ => null,
  };

  static _Tip? _tipFromCatalog(StruggleCatalog catalog, String code) {
    final image = _tipImage(code);
    if (image == null) return null;
    final remote = catalog.tip(code);
    final title = remote?.title.trim() ?? '';
    final body = remote?.body.trim() ?? '';
    return _Tip(
      image: image,
      code: code,
      title: title.isNotEmpty ? title : _localTitleKey(code).tr(),
      body: body.isNotEmpty ? body : _localBodyKey(code).tr(),
    );
  }

  static String _localTitleKey(String code) => switch (code) {
    'hydration' => 'fasting_struggle.hydration_title',
    'walk' => 'fasting_struggle.walk_title',
    'breathe' => 'fasting_struggle.breathe_title',
    _ => 'fasting_struggle.hydration_title',
  };

  static String _localBodyKey(String code) => switch (code) {
    'hydration' => 'fasting_struggle.hydration_body',
    'walk' => 'fasting_struggle.walk_body',
    'breathe' => 'fasting_struggle.breathe_body',
    _ => 'fasting_struggle.hydration_body',
  };

  void _backToTimer(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();
  }

  void _openTip(_Tip tip) {
    final extra = widget.args.bodyText;
    switch (tip.image) {
      case _TipImage.hydration:
        context.pushNamed(RoutePaths.fastingSipChallenge.name, extra: extra);
      case _TipImage.walk:
        context.pushNamed(RoutePaths.fastingQuickWalk.name, extra: extra);
      case _TipImage.breathe:
        context.pushNamed(RoutePaths.fastingBreath.name, extra: extra);
    }
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
              widget.args.bodyText,
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
                  unawaited(_logStruggle(widget.args.reason, _tips[i].code));
                  _openTip(_tips[i]);
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

/// Seçilen neden + ipucu sunucuya yazılır (hata akışı bozmaz).
Future<void> _logStruggle(FastingStruggleReason reason, String tip) async {
  try {
    await getIt<FastingRepository>().logStruggle(
      fastId: getIt<FastingSessionCubit>().state.fast?.id,
      reason: reason.name,
      tip: tip,
    );
  } on Object {
    // Kayıt olmazsa yalnızca istatistik eksik kalır.
  }
}

@immutable
final class _Tip {
  const _Tip({
    required this.image,
    required this.code,
    required this.title,
    required this.body,
  });

  final _TipImage image;
  final String code;
  final String title;
  final String body;

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
                        tip.title,
                        style: AppTextStyles.fastingStruggleOptionTitle,
                      ),
                      Text(
                        tip.body,
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
