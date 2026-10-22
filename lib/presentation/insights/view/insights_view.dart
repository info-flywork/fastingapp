import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/domain/content/content_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/insights/insight_topic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Profil → Insights. Konu kartları ve arama.
final class InsightsView extends StatefulWidget {
  const InsightsView({super.key});

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> {
  static const _topics = <_Topic>[
    _Topic(
      kind: InsightTopic.basics,
      image: _TopicImage.tree,
      titleKey: 'insights_page.basics_title',
      bodyKey: 'insights_page.basics_body',
      background: _TopicBackground.basics,
    ),
    _Topic(
      kind: InsightTopic.during,
      image: _TopicImage.flame,
      titleKey: 'insights_page.during_title',
      bodyKey: 'insights_page.during_body',
      background: _TopicBackground.during,
    ),
    _Topic(
      kind: InsightTopic.eating,
      image: _TopicImage.window,
      titleKey: 'insights_page.eating_title',
      bodyKey: 'insights_page.eating_body',
      background: _TopicBackground.eating,
    ),
    _Topic(
      kind: InsightTopic.health,
      image: _TopicImage.heart,
      titleKey: 'insights_page.health_title',
      bodyKey: 'insights_page.health_body',
      background: _TopicBackground.health,
    ),
    _Topic(
      kind: InsightTopic.tips,
      image: _TopicImage.star,
      titleKey: 'insights_page.tips_title',
      bodyKey: 'insights_page.tips_body',
      background: _TopicBackground.tips,
    ),
  ];

  static const _searchDebounce = Duration(milliseconds: 300);

  String _query = '';
  Timer? _searchTimer;

  /// Sunucu kategorileri (`/insights/categories`): başlık/açıklama; görsel ve
  /// renk yerel tasarımdan.
  Map<String, InsightCategory> _categories = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadCategories());
  }

  Future<void> _loadCategories() async {
    try {
      final c = await getIt<ContentRepository>().insightCategories();
      if (mounted) setState(() => _categories = Map.of(c));
    } on Object {
      // Yerel metinler kalır.
    }
  }

  String _titleOf(_Topic t) =>
      _categories[t.kind.name]?.title ?? t.titleKey.tr();

  String _bodyOf(_Topic t) =>
      _categories[t.kind.name]?.description ?? t.bodyKey.tr();

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  bool _matches(_Topic topic) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return _titleOf(topic).toLowerCase().contains(needle) ||
        _bodyOf(topic).toLowerCase().contains(needle);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: SafeArea(
          bottom: false,
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
            children: [
              _InsightsHeader(onSearchChanged: _onSearchChanged),
              const SizedBox(height: 16),
              for (var i = 0; i < _topics.length; i++)
                _TopicReveal(
                  visible: _matches(_topics[i]),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _topics.length - 1 ? 0 : 10,
                    ),
                    child: _TopicCard(
                      topic: _topics[i],
                      title: _titleOf(_topics[i]),
                      body: _bodyOf(_topics[i]),
                      locked:
                          _categories[_topics[i].kind.name]?.isLocked ?? false,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const _StepsBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

final class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader({required this.onSearchChanged});

  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -10,
          top: 5,
          child: IgnorePointer(
            child: AppImages.insightsss.image(
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 132),
              child: _HeaderCopy(),
            ),
            const SizedBox(height: 12),
            _SearchField(onChanged: onSearchChanged),
          ],
        ),
      ],
    );
  }
}

final class _HeaderCopy extends StatelessWidget {
  const _HeaderCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'insights_page.brand_mochi'.tr(),
                style: AppTextStyles.insightsBrand,
              ),
              TextSpan(
                text: 'insights_page.brand_fast'.tr(),
                style: AppTextStyles.insightsBrand.copyWith(
                  color: ColorName.colorCtaGradientBottom,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('insights_page.title'.tr(), style: AppTextStyles.insightsTitle),
        const SizedBox(height: 4),
        Text('insights_page.subtitle'.tr(), style: AppTextStyles.loginSlogan),
      ],
    );
  }
}

final class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            AppImages.searchpng.image(width: 20, height: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                style: AppTextStyles.insightsSearch.copyWith(
                  color: ColorName.colorTitle,
                ),
                cursorColor: ColorName.colorTitle,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'insights_page.search'.tr(),
                  hintStyle: AppTextStyles.insightsSearch,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TopicImage { tree, flame, window, heart, star }

enum _TopicBackground { basics, during, eating, health, tips }

@immutable
final class _Topic {
  const _Topic({
    required this.kind,
    required this.image,
    required this.titleKey,
    required this.bodyKey,
    required this.background,
  });

  final InsightTopic kind;

  final _TopicImage image;
  final String titleKey;
  final String bodyKey;
  final _TopicBackground background;

  AppImageAsset get asset => switch (image) {
    _TopicImage.tree => AppImages.tree,
    _TopicImage.flame => AppImages.flameCalories,
    _TopicImage.window => AppImages.eatWindow,
    _TopicImage.heart => AppImages.blueHearth,
    _TopicImage.star => AppImages.purpleStar,
  };

  Color get color => switch (background) {
    _TopicBackground.basics => ColorName.colorOptionSelected.withValues(
      alpha: 0.2,
    ),
    _TopicBackground.during => ColorName.colorInsightDuring,
    _TopicBackground.eating => ColorName.colorInsightEating,
    _TopicBackground.health => ColorName.colorInsightHealth,
    _TopicBackground.tips => ColorName.colorInsightTips,
  };
}

final class _TopicReveal extends StatelessWidget {
  const _TopicReveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        heightFactor: visible ? 1 : 0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          opacity: visible ? 1 : 0,
          child: child,
        ),
      ),
    );
  }
}

final class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.title,
    required this.body,
    required this.locked,
  });

  final _Topic topic;
  final String title;
  final String body;

  /// Sunucu `isLocked` (premium kategori). Önceden okunmuyordu: dokununca
  /// makale 402 ile açılmıyordu.
  final bool locked;

  Future<void> _open(BuildContext context) async {
    final revenueCat = getIt<RevenueCatService>();
    if (locked && !revenueCat.isPremium.value) {
      if (!await revenueCat.presentPaywall() || !context.mounted) return;
    }
    await context.pushNamed(
      RoutePaths.insightDetail.name,
      pathParameters: {'topic': topic.kind.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: topic.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => unawaited(_open(context)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ColorName.colorWhite.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: topic.asset.image(fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.proteinMealTitle),
                    Text(body, style: AppTextStyles.proteinMealMeta),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<bool>(
                valueListenable: getIt<RevenueCatService>().isPremium,
                builder: (context, premium, _) => locked && !premium
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AppImages.kingSl.image(width: 22, height: 22),
                      )
                    : const SizedBox.shrink(),
              ),
              Assets.icons.solarAltArrowLeftLinear.svg(
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  ColorName.colorTitle.withValues(alpha: 0.5),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StepsBanner extends StatelessWidget {
  const _StepsBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorInsightBanner,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.rotate(
              angle: 5.71 * -math.pi / 180,
              child: SizedBox(
                width: 130,
                child: Text(
                  'insights_page.banner'.tr(),
                  style: AppTextStyles.insightsBanner,
                ),
              ),
            ),

            AppImages.smallSteps.image(height: 73, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
