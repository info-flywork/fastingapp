import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/domain/content/content_repository.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// SSS / FAQ — dış container + border’lı accordion kartlar.
final class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  /// İlk soru açık; null = hiçbiri açık değil.
  int? _expandedIndex = 0;

  /// Sunucudaki SSS (`/catalog/faq`); gelene kadar / gelmezse yerel metinler.
  List<FaqItem>? _server;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final items = await getIt<ContentRepository>().faq();
      if (mounted && items.isNotEmpty) setState(() => _server = items);
    } on Object {
      // Yerel liste kalır.
    }
  }

  List<FaqItem> get _faq =>
      _server ??
      [
        for (final i in _items)
          FaqItem(question: i.questionKey.tr(), answer: i.answerKey.tr()),
      ];

  static const _items = <({String questionKey, String answerKey})>[
    (questionKey: 'faq.q_what', answerKey: 'faq.a_what'),
    (questionKey: 'faq.q_start', answerKey: 'faq.a_start'),
    (questionKey: 'faq.q_beginner', answerKey: 'faq.a_beginner'),
    (questionKey: 'faq.q_premium', answerKey: 'faq.a_premium'),
    (questionKey: 'faq.q_history', answerKey: 'faq.a_history'),
    (questionKey: 'faq.q_cancel', answerKey: 'faq.a_cancel'),
  ];

  void _onTap(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorProfileBack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: EditProfileAppBar(
                title: 'faq.title'.tr(),
                onBack: () => context.pop(),
                backButtonColor: ColorName.colorWhite,
              ),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
                  // Frame 48096383 — tüm soruları saran container
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ColorName.colorWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          for (final (i, item) in _faq.indexed) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _FaqCard(
                              question: item.question,
                              answer: item.answer,
                              isExpanded: _expandedIndex == i,
                              onTap: () => _onTap(i),
                            ),
                          ],
                        ],
                      ),
                    ),
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

/// Tek FAQ kartı — border 2px %5, r16, p12.
final class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: ColorName.colorWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 2,
              color: ColorName.colorBlack.withValues(alpha: 0.05),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(question, style: AppTextStyles.faqQuestion),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: isExpanded ? -0.25 : 0.25,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Assets.icons.solarAltArrowLeftLinear.svg(
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          ColorName.colorTitle.withValues(alpha: 0.5),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10, right: 30),
                          child: Text(answer, style: AppTextStyles.faqAnswer),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
