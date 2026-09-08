part of '../noted_highlight_view.dart';

mixin NotedHighlightViewMixin on State<NotedHighlightView> {
  static const _skipTitleKeys = <OnboardingFoodSkip, String>{
    OnboardingFoodSkip.mushrooms: 'onboarding.food_skip_mushrooms',
    OnboardingFoodSkip.olives: 'onboarding.food_skip_olives',
    OnboardingFoodSkip.seafood: 'onboarding.food_skip_seafood',
    OnboardingFoodSkip.onions: 'onboarding.food_skip_onions',
    OnboardingFoodSkip.broccoli: 'onboarding.food_skip_broccoli',
    OnboardingFoodSkip.tooSpicy: 'onboarding.food_skip_too_spicy',
    OnboardingFoodSkip.dairy: 'onboarding.food_skip_dairy',
    OnboardingFoodSkip.nuts: 'onboarding.food_skip_nuts',
    OnboardingFoodSkip.beans: 'onboarding.food_skip_beans',
    OnboardingFoodSkip.eggplant: 'onboarding.food_skip_eggplant',
  };

  List<String> skipLabels(Set<OnboardingFoodSkip> skips) {
    return skips
        .map((s) => (_skipTitleKeys[s] ?? '').tr().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String summaryChipLabel({required int favourites, required int skips}) {
    return 'onboarding.noted_summary'.tr(
      args: ['$favourites', '$skips'],
    );
  }

  Widget buildNotedSubtitle(Set<OnboardingFoodSkip> skips) {
    final labels = skipLabels(skips);
    final base = AppTextStyles.highlightSubtitle;
    final bold = AppTextStyles.highlightSubtitleEmphasis;

    if (labels.isEmpty) {
      return Text(
        'onboarding.noted_subtitle_no_skips'.tr(),
        textAlign: TextAlign.center,
        style: base,
      );
    }

    final children = <InlineSpan>[
      TextSpan(text: 'onboarding.noted_subtitle_no_prefix'.tr(), style: base),
    ];

    for (var i = 0; i < labels.length; i++) {
      if (i > 0) {
        final isLast = i == labels.length - 1;
        children.add(
          TextSpan(
            text: isLast
                ? 'onboarding.noted_subtitle_or'.tr()
                : 'onboarding.noted_subtitle_comma'.tr(),
            style: base,
          ),
        );
      }
      children.add(TextSpan(text: labels[i], style: bold));
    }

    children.add(
      TextSpan(
        text: 'onboarding.noted_subtitle_suffix'.tr(),
        style: base,
      ),
    );

    return Text.rich(
      TextSpan(children: children),
      textAlign: TextAlign.center,
    );
  }

  void onContinue() {
    context.push(RoutePaths.weightHistory.path);
  }
}
