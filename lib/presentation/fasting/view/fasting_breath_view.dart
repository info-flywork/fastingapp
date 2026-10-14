import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_feeling_better_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 4-7-8 nefesi — 4 tur.
final class FastingBreathView extends StatefulWidget {
  const FastingBreathView({required this.bodyText, super.key});

  final String bodyText;

  @override
  State<FastingBreathView> createState() => _FastingBreathViewState();
}

enum _BreathPhase { inhale, hold, exhale }

const _breathRounds = 4;

class _FastingBreathViewState extends State<FastingBreathView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phaseTimer;
  _BreathPhase _phase = _BreathPhase.inhale;
  int _round = 0;
  bool _started = false;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _phaseTimer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener(_onPhase);
  }

  void _onPhase(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _advance();
  }

  @override
  void dispose() {
    _phaseTimer
      ..removeStatusListener(_onPhase)
      ..dispose();
    super.dispose();
  }

  int _seconds(_BreathPhase phase) => switch (phase) {
    _BreathPhase.inhale => 4,
    _BreathPhase.hold => 7,
    _BreathPhase.exhale => 8,
  };

  String _phaseKey(_BreathPhase phase) => switch (phase) {
    _BreathPhase.inhale => 'fasting_struggle.breathe_inhale',
    _BreathPhase.hold => 'fasting_struggle.breathe_hold',
    _BreathPhase.exhale => 'fasting_struggle.breathe_exhale',
  };

  void _play(_BreathPhase phase, {required int round}) {
    setState(() {
      _phase = phase;
      _round = round;
      _started = true;
    });
    _phaseTimer.duration = Duration(seconds: _seconds(phase));
    _phaseTimer.forward(from: 0);
  }

  void _advance() {
    if (_phase != _BreathPhase.exhale) {
      final next = _phase == _BreathPhase.inhale
          ? _BreathPhase.hold
          : _BreathPhase.exhale;
      _play(next, round: _round);
      return;
    }
    final nextRound = _round + 1;
    if (nextRound >= _breathRounds) {
      setState(() => _celebrating = true);
      return;
    }
    _play(_BreathPhase.inhale, round: nextRound);
  }

  void _onBegin() {
    if (_started || _celebrating) return;
    _play(_BreathPhase.inhale, round: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_celebrating) return const FastingFeelingBetterView();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: ColorName.colorWhite,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 24),
          children: [
            const _BackRow(),
            const SizedBox(height: 40),
            Center(
              child: Transform.scale(
                scale: 1.1,
                child: AppImages.mascotBreath.image(
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'fasting_struggle.says'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleTitle,
            ),
            const SizedBox(height: 12),
            Text(
              widget.bodyText,
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleBody,
            ),
            const SizedBox(height: 32),
            _BreathCard(
              started: _started,
              phase: _phase,
              phaseKey: _phaseKey(_phase),
              phaseSeconds: _seconds(_phase),
              round: _round + 1,
              timer: _phaseTimer,
              onBegin: _onBegin,
            ),
          ],
        ),
      ),
    );
  }
}

final class _BackRow extends StatelessWidget {
  const _BackRow();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => context.pop(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.icons.solarArrowLeftLinear1.image(
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Text(
                'notifications.back'.tr(),
                style: AppTextStyles.fastingStruggleBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _BreathCard extends StatelessWidget {
  const _BreathCard({
    required this.started,
    required this.phase,
    required this.phaseKey,
    required this.phaseSeconds,
    required this.round,
    required this.timer,
    required this.onBegin,
  });

  final bool started;
  final _BreathPhase phase;
  final String phaseKey;
  final int phaseSeconds;
  final int round;
  final AnimationController timer;
  final VoidCallback onBegin;

  double _ringScale(double t) {
    final eased = Curves.easeInOut.transform(t);
    return switch (phase) {
      _BreathPhase.inhale => 0.62 + (0.38 * eased),
      _BreathPhase.hold => 1,
      _BreathPhase.exhale => 1 - (0.38 * eased),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            width: 2,
          ),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 480),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              );
            },
            transitionBuilder: (child, animation) {
              final scale = Tween<double>(
                begin: 0.92,
                end: 1,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  alignment: Alignment.topCenter,
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: Padding(
              key: ValueKey(started),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (!started) ...[
                    AppImages.breathe.image(
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'fasting_struggle.breathe_session_title'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingStruggleOptionTitle,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'fasting_struggle.breathe_session_body'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingStruggleOptionBody,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 198,
                      child: AppButton(
                        label: 'fasting_struggle.breathe_begin'.tr(),
                        onPressed: onBegin,
                        showIcon: false,
                        expand: false,
                        decoration: AppButtonDecoration.homeJoin(),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'fasting_struggle.breathe_round'.tr(args: ['$round']),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fastingStruggleOptionTitle,
                    ),
                    const SizedBox(height: 10),
                    _BreathRing(
                      timer: timer,
                      phaseKey: phaseKey,
                      phaseSeconds: phaseSeconds,
                      scaleFor: _ringScale,
                    ),
                    const SizedBox(height: 10),
                    _PhaseDots(phase: phase),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _BreathRing extends StatelessWidget {
  const _BreathRing({
    required this.timer,
    required this.phaseKey,
    required this.phaseSeconds,
    required this.scaleFor,
  });

  final AnimationController timer;
  final String phaseKey;
  final int phaseSeconds;
  final double Function(double t) scaleFor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: timer,
        builder: (context, _) {
          final t = timer.value.clamp(0.0, 1.0);
          final left = (phaseSeconds * (1 - t)).ceil().clamp(0, phaseSeconds);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scaleFor(t),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorName.colorCtaGradientBottom,
                      width: 2,
                    ),
                  ),
                  child: const SizedBox(width: 200, height: 200),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$left', style: AppTextStyles.fastingBreathCount),
                  Text(
                    phaseKey.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.fastingBreathPhase,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _PhaseDots extends StatelessWidget {
  const _PhaseDots({required this.phase});

  final _BreathPhase phase;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _BreathPhase.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: i == phase.index
                  ? ColorName.colorCtaGradientBottom
                  : ColorName.colorPlanBoltInactive,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(width: 13, height: 13),
          ),
        ],
      ],
    );
  }
}
