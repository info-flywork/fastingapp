import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/onboarding/weight_projection_chart.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/weight_projection_view_mixin.dart';

/// Building plan sonrası kilo projeksiyonu ekranı.
final class WeightProjectionView extends StatefulWidget {
  const WeightProjectionView({
    this.currentWeightKg = 74,
    this.goalWeightKg = 68,
    this.weeklyLossKg = 0.4,
    super.key,
  });

  final double currentWeightKg;
  final double goalWeightKg;
  final double weeklyLossKg;

  @override
  State<WeightProjectionView> createState() => _WeightProjectionViewState();
}

class _WeightProjectionViewState extends State<WeightProjectionView>
    with WeightProjectionViewMixin, SingleTickerProviderStateMixin {
  late final AnimationController _chartController;
  late final Animation<double> _chartProgress;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _chartProgress = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOutCubic,
    );
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _chartController.forward();
    });
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final targetDate = projectedTargetDate(
      currentKg: widget.currentWeightKg,
      goalKg: widget.goalWeightKg,
      weeklyLossKg: widget.weeklyLossKg,
    );
    final dateLabel = DateFormat.MMMMd(locale).format(targetDate);
    final weekly = widget.weeklyLossKg.toStringAsFixed(1);
    final current = widget.currentWeightKg.toStringAsFixed(1);
    final goal = widget.goalWeightKg.toStringAsFixed(1);
    final goalInt = widget.goalWeightKg == widget.goalWeightKg.roundToDouble()
        ? widget.goalWeightKg.toInt().toString()
        : goal;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorName.colorWeightProjectionBgTop,
                ColorName.colorWeightProjectionBgBottom,
              ],
            ),
          ),
          child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Column(
                    children: [
                      Text(
                        'onboarding.weight_projection_eyebrow'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.weightProjectionEyebrow,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'onboarding.weight_projection_weight'.tr(args: [goalInt]),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.weightProjectionHero,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'onboarding.weight_projection_by'.tr(args: [dateLabel]),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.weightProjectionDate,
                      ),
                      const SizedBox(height: 28),
                      AnimatedBuilder(
                        animation: _chartProgress,
                        builder: (context, _) {
                          return WeightProjectionChart(
                            progress: _chartProgress.value,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current,
                                  style:
                                      AppTextStyles.weightProjectionTodayValue,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'onboarding.weight_projection_today'.tr(),
                                  style:
                                      AppTextStyles.weightProjectionAxisLabel,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  goal,
                                  style:
                                      AppTextStyles.weightProjectionGoalValue,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'onboarding.weight_projection_goal'.tr(),
                                  style:
                                      AppTextStyles.weightProjectionAxisLabel,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'onboarding.weight_projection_body'.tr(args: [weekly]),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.weightProjectionBody,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: AppButton(
                  label: 'onboarding.weight_projection_cta'.tr(),
                  onPressed: onContinue,
                  showIcon: false,
                  decoration: AppButtonDecoration.onLight(),
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
