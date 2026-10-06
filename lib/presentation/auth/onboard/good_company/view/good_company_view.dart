import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/data/model/auth/auth_response.dart';
import 'package:fastingapp/data/model/token/token.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/good_company_view_mixin.dart';
part 'widgets/good_company_review_card.dart';
part 'widgets/good_company_stat_card.dart';

/// Weight projection sonrası sosyal kanıt ekranı.
final class GoodCompanyView extends StatefulWidget {
  const GoodCompanyView({super.key});

  @override
  State<GoodCompanyView> createState() => _GoodCompanyViewState();
}

class _GoodCompanyViewState extends State<GoodCompanyView>
    with GoodCompanyViewMixin {
  static const _iconTilt = 5 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorWhite,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _StarRow(size: 32, gap: 2),
                            const SizedBox(height: 12),
                            Text(
                              'onboarding.good_company_title'.tr(),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.goodCompanyTitle,
                            ),
                            const SizedBox(height: 28),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: GoodCompanyStatCard(
                                      value:
                                          'onboarding.good_company_streak_value'
                                              .tr(),
                                      label:
                                          'onboarding.good_company_streak_label'
                                              .tr(),
                                      valueColor: ColorName.colorCompanyStreak,
                                      iconPath: Assets.images.streak.path,
                                      iconTiltRadians: _iconTilt,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GoodCompanyStatCard(
                                      value:
                                          'onboarding.good_company_active_value'
                                              .tr(),
                                      label:
                                          'onboarding.good_company_active_label'
                                              .tr(),
                                      valueColor: ColorName.colorCompanyActive,
                                      iconPath: Assets.images.seeStar.path,
                                      iconTiltRadians: _iconTilt,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GoodCompanyStatCard(
                                      value:
                                          'onboarding.good_company_rating_value'
                                              .tr(),
                                      label:
                                          'onboarding.good_company_rating_label'
                                              .tr(),
                                      valueColor: ColorName.colorCompanyRating,
                                      iconPath: Assets.images.star.path,
                                      iconTiltRadians: _iconTilt,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GoodCompanyReviewCard(
                              name: 'onboarding.good_company_reviewer'.tr(),
                              quote: 'onboarding.good_company_quote'.tr(),
                              avatarPath: Assets.images.tirtil.path,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AppButton(
                  label: 'onboarding.good_company_cta'.tr(),
                  onPressed: onContinue,
                  showIcon: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.size,
    required this.gap,
    this.alignment = MainAxisAlignment.center,
  });

  final double size;
  final double gap;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Image.asset(
            Assets.images.star.path,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ],
      ],
    );
  }
}
