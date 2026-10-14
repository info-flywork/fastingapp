import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:flutter/foundation.dart';

/// Insights listesindeki konu. Detay metni bu kimliğe göre değişir.
enum InsightTopic {
  basics,
  during,
  eating,
  health,
  tips;

  static InsightTopic fromName(String? name) {
    return InsightTopic.values.firstWhere(
      (topic) => topic.name == name,
      orElse: () => InsightTopic.basics,
    );
  }

  String get _prefix => 'insights_detail.$name';

  String get kickerKey => '$_prefix.kicker';

  String get titleKey => '$_prefix.title';

  String get subtitleKey => '$_prefix.subtitle';

  String get quoteKey => '$_prefix.quote';

  String get tipKey => '$_prefix.tip';

  List<InsightDetailCard> get cards => switch (this) {
    InsightTopic.basics => const [
      InsightDetailCard(icon: InsightDetailIcon.tree, index: 1),
      InsightDetailCard(icon: InsightDetailIcon.flame, index: 2),
      InsightDetailCard(icon: InsightDetailIcon.window, index: 3),
    ],
    InsightTopic.during => const [
      InsightDetailCard(icon: InsightDetailIcon.flame, index: 1),
      InsightDetailCard(icon: InsightDetailIcon.heart, index: 2),
      InsightDetailCard(icon: InsightDetailIcon.tree, index: 3),
    ],
    InsightTopic.eating => const [
      InsightDetailCard(icon: InsightDetailIcon.window, index: 1),
      InsightDetailCard(icon: InsightDetailIcon.flame, index: 2),
      InsightDetailCard(icon: InsightDetailIcon.tree, index: 3),
    ],
    InsightTopic.health => const [
      InsightDetailCard(icon: InsightDetailIcon.heart, index: 1),
      InsightDetailCard(icon: InsightDetailIcon.flame, index: 2),
      InsightDetailCard(icon: InsightDetailIcon.tree, index: 3),
    ],
    InsightTopic.tips => const [
      InsightDetailCard(icon: InsightDetailIcon.star, index: 1),
      InsightDetailCard(icon: InsightDetailIcon.tree, index: 2),
      InsightDetailCard(icon: InsightDetailIcon.flame, index: 3),
    ],
  };
}

enum InsightDetailIcon {
  tree,
  flame,
  window,
  heart,
  star;

  static InsightDetailIcon fromName(String name) => InsightDetailIcon.values
      .firstWhere((i) => i.name == name, orElse: () => InsightDetailIcon.tree);
}

/// Detay ekranının metinleri: sunucu makalesi (`/insights/articles/:slug`)
/// ya da (yüklenene kadar / yoksa) yerel çeviriler.
@immutable
final class InsightContent {
  const InsightContent({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.quote,
    required this.tip,
    required this.cards,
  });

  factory InsightContent.local(InsightTopic topic) => InsightContent(
    kicker: topic.kickerKey.tr(),
    title: topic.titleKey.tr(),
    subtitle: topic.subtitleKey.tr(),
    quote: topic.quoteKey.tr(),
    tip: topic.tipKey.tr(),
    cards: [
      for (final c in topic.cards)
        (
          asset: c.asset,
          title: c.titleKey(topic).tr(),
          body: c.bodyKey(topic).tr(),
        ),
    ],
  );

  final String kicker;
  final String title;
  final String subtitle;
  final String quote;
  final String tip;
  final List<({AppImageAsset asset, String title, String body})> cards;
}

@immutable
final class InsightDetailCard {
  const InsightDetailCard({required this.icon, required this.index});

  final InsightDetailIcon icon;
  final int index;

  String titleKey(InsightTopic topic) =>
      'insights_detail.${topic.name}.card${index}_title';

  String bodyKey(InsightTopic topic) =>
      'insights_detail.${topic.name}.card${index}_body';

  AppImageAsset get asset => switch (icon) {
    InsightDetailIcon.tree => AppImages.tree,
    InsightDetailIcon.flame => AppImages.flameCalories,
    InsightDetailIcon.window => AppImages.eatWindow,
    InsightDetailIcon.heart => AppImages.blueHearth,
    InsightDetailIcon.star => AppImages.purpleStar,
  };
}
