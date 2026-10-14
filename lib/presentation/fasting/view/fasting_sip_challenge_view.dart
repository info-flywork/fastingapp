import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_feeling_better_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Su molası — 8 yudumluk görev. Her dokunuş bir yudum sayar.
final class FastingSipChallengeView extends StatefulWidget {
  const FastingSipChallengeView({required this.bodyText, super.key});

  final String bodyText;

  @override
  State<FastingSipChallengeView> createState() =>
      _FastingSipChallengeViewState();
}

const _sipCount = 8;

class _FastingSipChallengeViewState extends State<FastingSipChallengeView> {
  int _sips = 0;
  bool _celebrating = false;
  Timer? _celebrateTimer;

  @override
  void dispose() {
    _celebrateTimer?.cancel();
    super.dispose();
  }

  void _backToTimer(BuildContext context) {
    context.pop();
  }

  void _addSip() {
    if (_sips >= _sipCount || _celebrating) return;
    setState(() => _sips++);
    if (_sips < _sipCount) return;
    _celebrateTimer?.cancel();
    _celebrateTimer = Timer(const Duration(milliseconds: 720), () {
      if (!mounted) return;
      setState(() => _celebrating = true);
    });
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
            _BackRow(onTap: () => _backToTimer(context)),
            const SizedBox(height: 16),
            Center(
              child: Transform.scale(
                scale: 1.2,
                child: AppImages.mascotWater.image(
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
            _SipCard(sips: _sips),
            const SizedBox(height: 32),
            Center(child: _SipButton(onTap: _addSip)),
            const SizedBox(height: 12),
            Text(
              'fasting_struggle.sip_hint'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleOptionBody,
            ),
          ],
        ),
      ),
    );
  }
}

final class _BackRow extends StatelessWidget {
  const _BackRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
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

final class _SipCard extends StatelessWidget {
  const _SipCard({required this.sips});

  final int sips;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorName.colorBlack.withValues(alpha: 0.05),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AppImages.blob.image(width: 48, height: 48, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text(
              'fasting_struggle.sip_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleOptionTitle,
            ),
            const SizedBox(height: 6),
            Text(
              'fasting_struggle.sip_progress'.tr(args: ['$sips']),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleOptionBody,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _sipCount; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _SipDot(key: ValueKey('sip-$i'), filled: i < sips),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _SipButton extends StatefulWidget {
  const _SipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SipButton> createState() => _SipButtonState();
}

class _SipButtonState extends State<_SipButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0.78,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.78,
          end: 1.16,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.16,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: ColorName.colorWhite,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _handleTap,
          customBorder: const CircleBorder(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorName.colorBlack.withValues(alpha: 0.05),
                width: 2,
              ),
            ),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AppImages.blob.image(fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _SipDot extends StatefulWidget {
  const _SipDot({required this.filled, super.key});

  final bool filled;

  @override
  State<_SipDot> createState() => _SipDotState();
}

class _SipDotState extends State<_SipDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.filled) _controller.value = 1;
  }

  @override
  void didUpdateWidget(_SipDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filled && !oldWidget.filled) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _unit(double value) => value.clamp(0.0, 1.0);

  double _pop(double t) {
    final progress = _unit(t);
    if (progress < 0.42) {
      final local = Curves.easeOut.transform(_unit(progress / 0.42));
      return 0.3 + (1.7 - 0.3) * local;
    }
    final local = Curves.easeOut.transform(_unit((progress - 0.42) / 0.58));
    return 1.7 + (1 - 1.7) * local;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 21,
      height: 21,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = widget.filled ? _unit(_controller.value) : 0.0;
          final color = Color.lerp(
            ColorName.colorPlanBoltInactive,
            ColorName.colorWaterAction,
            Curves.easeOut.transform(t),
          );
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (t > 0 && t < 1)
                Opacity(
                  opacity: (1 - t).clamp(0, 1),
                  child: Transform.scale(
                    scale: 1 + t * 2.2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorName.colorWaterAction,
                          width: 2,
                        ),
                      ),
                      child: const SizedBox(width: 21, height: 21),
                    ),
                  ),
                ),
              Transform.scale(
                scale: widget.filled ? _pop(t) : 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(width: 21, height: 21),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
