import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/insights/insight_topic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Insights konusu — soru, cevap kartları ve Mochi ipucu.
final class InsightDetailView extends StatelessWidget {
  const InsightDetailView({required this.topic, super.key});

  final InsightTopic topic;

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
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 16),
            children: [
              _DetailHeader(topic: topic),
              const SizedBox(height: 16),
              for (final card in topic.cards) ...[
                _AnswerCard(topic: topic, card: card),
                const SizedBox(height: 12),
              ],
              _TipCard(topic: topic),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.topic});

  final InsightTopic topic;

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
                    topic.kickerKey.tr(),
                    style: AppTextStyles.insightDetailKicker,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(right: titleRight),
                  child: Text(
                    topic.titleKey.tr(),
                    style: AppTextStyles.insightsTitle,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(right: side),
                  child: Text(
                    topic.subtitleKey.tr(),
                    style: AppTextStyles.loginSlogan,
                  ),
                ),
                const SizedBox(height: 16),
                _QuoteCard(topic: topic),
              ],
            ),
          ],
        );
      },
    );
  }
}

final class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.topic});

  final InsightTopic topic;

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
                    child: Text(
                      topic.quoteKey.tr(),
                      style: AppTextStyles.insightsSearch,
                    ),
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
  const _AnswerCard({required this.topic, required this.card});

  final InsightTopic topic;
  final InsightDetailCard card;

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
                  Text(
                    card.titleKey(topic).tr(),
                    style: AppTextStyles.proteinMealTitle,
                  ),
                  Text(
                    card.bodyKey(topic).tr(),
                    style: AppTextStyles.proteinMealMeta,
                  ),
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
  const _TipCard({required this.topic});

  final InsightTopic topic;

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
                  Text(topic.tipKey.tr(), style: AppTextStyles.proteinMealMeta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
