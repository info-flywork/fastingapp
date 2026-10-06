import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/onboarding/building_plan_progress_bar.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// "Body data" / "Lifestyle & Targets" progress bölümü.
final class BuildingPlanSection extends StatelessWidget {
  const BuildingPlanSection({
    required this.title,
    required this.progress,
    required this.chips,
    required this.isComplete,
    this.showChips = true,
    this.showProgressBar = true,
    super.key,
  });

  final String title;
  final double progress;
  final List<String> chips;
  final bool isComplete;
  final bool showChips;
  final bool showProgressBar;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: AppTextStyles.buildingPlanSectionTitle),
            ),
            if (isComplete)
              appImage(
                AppImages.greenTick.path,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              )
            else
              Text('$percent%', style: AppTextStyles.buildingPlanSectionTitle),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: showChips && chips.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < chips.length; i++)
                        _AnimatedChip(
                          key: ValueKey(chips[i]),
                          label: chips[i],
                          delay: Duration(milliseconds: 55 * i),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (showProgressBar) ...[
          const SizedBox(height: 12),
          BuildingPlanProgressBar(progress: progress, showHead: !isComplete),
        ],
      ],
    );
  }
}

final class _AnimatedChip extends StatefulWidget {
  const _AnimatedChip({required this.label, required this.delay, super.key});

  final String label;
  final Duration delay;

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(curved);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: _Chip(label: widget.label),
        ),
      ),
    );
  }
}

final class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 2,
          color: ColorName.colorBlack.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label, style: AppTextStyles.buildingPlanChip),
      ),
    );
  }
}
