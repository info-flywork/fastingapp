import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/domain/content/content_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/insights/insight_topic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Insights konusu — soru, cevap kartları ve Mochi ipucu. Metin sunucu
/// makalesinden (`/insights/articles/:slug`); yüklenene kadar yerel.
final class InsightDetailView extends StatefulWidget {
  const InsightDetailView({required this.topic, super.key});

  final InsightTopic topic;

  @override
  State<InsightDetailView> createState() => _InsightDetailViewState();
}

class _InsightDetailViewState extends State<InsightDetailView> {
  InsightContent? _server;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final article = await getIt<ContentRepository>().insightArticleFor(
        widget.topic.name,
      );
      if (article == null || !mounted) return;
      setState(() => _server = _fromArticle(article));
    } on Object {
      // Yerel metin kalır.
    }
  }

  static InsightContent _fromArticle(InsightArticle a) => InsightContent(
    kicker: a.kicker,
    title: a.title,
    subtitle: a.subtitle ?? '',
    quote: a.quote ?? '',
    tip: a.tip ?? '',
    cards: [
      for (final s in a.sections)
        (
          asset: InsightDetailCard(
            icon: InsightDetailIcon.fromName(s.icon),
            index: 0,
          ).asset,
          title: s.title,
          body: s.body,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final content = _server ?? InsightContent.local(widget.topic);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: SafeArea(
          bottom: false,
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 16),
            children: [
              _DetailHeader(content: content),
              const SizedBox(height: 16),
              for (final card in content.cards) ...[
                _AnswerCard(card: card),
                const SizedBox(height: 12),
              ],
              if (content.tip.isNotEmpty) _TipCard(tip: content.tip),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.content});

  final InsightContent content;

  static const _mascotMaxWidth = 164.0;
  static const _mascotHeightRatio = 214 / 164;

  /// En uzun başlık kelimesi ~228px. Daha dar kolon kelimeyi böler.
  static const _titleMinWidth = 240.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const overhang = 16.0;
        const handFraction = 0.08;
        final mascotWidth =
            ((width + overhang - (_titleMinWidth + 6)) / (1 - handFraction))
                .clamp(120.0, _mascotMaxWidth);
        final side = math.max(0.0, mascotWidth - overhang);
        final titleRight = math.max(0.0, width - _titleMinWidth);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              right: -overhang,
              child: IgnorePointer(
                child: AppImages.mascotLearnDetail.image(
                  width: mascotWidth,
                  height: mascotWidth * _mascotHeightRatio,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: side),
                  child: Text(
                    content.kicker,
                    style: AppTextStyles.insightDetailKicker,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(right: titleRight),
                  child: Text(
                    content.title,
                    style: AppTextStyles.insightsTitle,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(right: side),
                  child: Text(
                    content.subtitle,
                    style: AppTextStyles.loginSlogan,
                  ),
                ),
                const SizedBox(height: 16),
                if (content.quote.isNotEmpty) _QuoteCard(quote: content.quote),
              ],
            ),
          ],
        );
      },
    );
  }
}

final class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorInsightQuoteBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ClipRect(
                      child: SizedBox(
                        width: 40,
                        height: 24,
                        child: Transform.rotate(
                          angle: math.pi,
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            maxWidth: 50,
                            maxHeight: 56,
                            child: Text(
                              '“',
                              style: AppTextStyles.insightQuoteMark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(quote, style: AppTextStyles.insightsSearch),
                  ),
                ],
              ),
              Text(
                'insights_detail.author'.tr(),
                textAlign: TextAlign.right,
                style: AppTextStyles.insightQuoteAuthor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.card});

  final ({AppImageAsset asset, String title, String body}) card;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            card.asset.image(width: 40, height: 40, fit: BoxFit.contain),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title, style: AppTextStyles.proteinMealTitle),
                  Text(card.body, style: AppTextStyles.proteinMealMeta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorInsightQuoteBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppImages.mascotTip.image(
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'insights_detail.tip_title'.tr(),
                    style: AppTextStyles.insightTipTitle,
                  ),
                  Text(tip, style: AppTextStyles.proteinMealMeta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
