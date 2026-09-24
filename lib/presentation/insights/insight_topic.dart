import 'package:fastingapp/generated/assets.gen.dart';

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

enum InsightDetailIcon { tree, flame, window, heart, star }

final class InsightDetailCard {
  const InsightDetailCard({required this.icon, required this.index});

  final InsightDetailIcon icon;
  final int index;

  String titleKey(InsightTopic topic) =>
      'insights_detail.${topic.name}.card${index}_title';

  String bodyKey(InsightTopic topic) =>
      'insights_detail.${topic.name}.card${index}_body';

  AssetGenImage get asset => switch (icon) {
    InsightDetailIcon.tree => Assets.images.tree,
    InsightDetailIcon.flame => Assets.images.flameCalories,
    InsightDetailIcon.window => Assets.images.eatWindow,
    InsightDetailIcon.heart => Assets.images.blueHearth,
    InsightDetailIcon.star => Assets.images.purpleStar,
  };
}
