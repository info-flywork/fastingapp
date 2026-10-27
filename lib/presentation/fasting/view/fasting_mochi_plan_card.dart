import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/domain/fasting/mochi_plan_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Fasting sayfası altı — Mochi'nin bugünkü önerisi.
/// Üstteki yay kullanıcının o anki orucudur; burası onun kopyası değildir.
final class FastingMochiPlanCard extends StatefulWidget {
  const FastingMochiPlanCard({required this.onStart, super.key});

  /// Çıkış / hesap değişimi: önceki kullanıcının planı görünmesin.
  static void clearCache() => _FastingMochiPlanCardState._lastPlan = null;

  final ValueChanged<MochiDailyPlan> onStart;

  static const _arcDiameter = 280.0;

  @override
  State<FastingMochiPlanCard> createState() => _FastingMochiPlanCardState();
}

class _FastingMochiPlanCardState extends State<FastingMochiPlanCard> {
  /// Son plan (oturum boyunca): kart yeniden kurulunca boş gelip sonra
  /// açılmasın; arkadan sessizce tazelenir.
  static MochiDailyPlan? _lastPlan;

  MochiDailyPlan? _plan = _lastPlan;
  var _refreshed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final plan = await getIt<MochiPlanRepository>().getPlan();
      _lastPlan = plan;
      if (!mounted) return;
      setState(() => _plan = plan);
      if (!plan.settled && !_refreshed) {
        _refreshed = true;
        await Future<void>.delayed(const Duration(seconds: 3));
        if (mounted) await _load();
      }
    } on Object {
      if (!mounted || _plan != null) return;
      setState(() => _plan = MochiDailyPlan.fallback());
    }
  }

  String _clock(DateTime time) =>
      DateFormat('HH:mm', context.locale.toString()).format(time);

  String _insight(MochiDailyPlan plan) {
    final text = plan.insight?.trim();
    if (text != null && text.isNotEmpty) return text;
    final key = 'fasting_page.mochi_plan_reason_${plan.reason}';
    final translated = key.tr();
    if (translated == key) return 'fasting_page.mochi_plan_insight'.tr();
    return translated;
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: 16),
          if (plan == null)
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _ArcBlock(
              progress: plan.fastHours / (plan.fastHours + plan.eatHours),
              fastHours: plan.fastHours,
              eatHours: plan.eatHours,
            ),
            _TimeRow(started: _clock(plan.startsAt), ends: _clock(plan.endsAt)),
            const SizedBox(height: 16),
            _InsightBox(text: _insight(plan)),
            const SizedBox(height: 16),
            AppButton(
              label: 'fasting_page.mochi_plan_start'.tr(),
              onPressed: () => widget.onStart(plan),
              showIcon: false,
              decoration: AppButtonDecoration.hungerResult(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Figma Frame 1597878668 — beyaz container title/subtitle;
/// büyütülmüş mascot üst/alttan clip edilir.
final class _Header extends StatelessWidget {
  const _Header();

  static const _mascotSize = 80.0;
  static const _radius = 16.0;
  static const _pad = 12.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: ColoredBox(
        color: ColorName.colorWhite,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _pad + _mascotSize * 0.72 + _gap,
                _pad,
                _pad,
                _pad,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'fasting_page.mochi_plan_title'.tr(),
                    style: AppTextStyles.fastingMochiPlanTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'fasting_page.mochi_plan_subtitle'.tr(),
                    style: AppTextStyles.fastingMochiPlanSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              left: _pad * 0.5,
              top: 0,
              bottom: 0,
              width: _mascotSize,
              child: Center(
                child: Transform.scale(
                  scale: 1.2,
                  child: AppImages.mascotHiWithout.image(
                    width: _mascotSize,
                    height: _mascotSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ArcBlock extends StatelessWidget {
  const _ArcBlock({
    required this.progress,
    required this.fastHours,
    required this.eatHours,
  });

  final double progress;
  final int fastHours;
  final int eatHours;

  @override
  Widget build(BuildContext context) {
    const d = FastingMochiPlanCard._arcDiameter;
    // Kalın stroke (stroke+4) üst/yanlardan kesilmesin.
    const inset = 12.0;

    return SizedBox(
      height: d * 0.82 + inset,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: inset - 10,
            left: 0,
            right: 0,
            height: d + 5,
            child: Stack(
              children: [
                HorseshoeArc(
                  progress: progress,
                  diameter: d,
                  trackColor: ColorName.colorUnitToggleBg,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'fasting_page.mochi_plan_fasting'.tr(),
                  style: AppTextStyles.fastingMochiPlanArcLabel,
                ),
                Text(
                  'fasting_page.mochi_plan_duration'.tr(
                    args: ['$fastHours', '00'],
                  ),
                  style: AppTextStyles.fastingMochiPlanDuration,
                ),
                const SizedBox(height: 4),
                _EatingChip(eatHours: eatHours),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma Frame 48096390 — hug, radius 21.42, pad 10.71 / 2.68, #FFFFFF.
final class _EatingChip extends StatelessWidget {
  const _EatingChip({required this.eatHours});

  final int eatHours;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(21.42),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.71, vertical: 2.68),
        child: Text(
          'fasting_page.mochi_plan_eating'.tr(args: ['$eatHours']),
          style: AppTextStyles.fastingMochiPlanEating,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

final class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.started, required this.ends});

  final String started;
  final String ends;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'fasting_page.started_label'.tr(),
                style: AppTextStyles.fastingBoundLabel,
              ),
              Text(started, style: AppTextStyles.fastingBoundValue),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'fasting_page.ends_label'.tr(),
                style: AppTextStyles.fastingBoundLabel,
              ),
              Text(ends, style: AppTextStyles.fastingBoundValue),
            ],
          ),
        ),
      ],
    );
  }
}

final class _InsightBox extends StatelessWidget {
  const _InsightBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorName.colorFlipClock),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: AppTextStyles.fastingMochiPlanInsight),
      ),
    );
  }
}
