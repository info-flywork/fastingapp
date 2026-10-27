import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/dialogs/widgets/water_edit_dialog.dart';
import 'package:fastingapp/core/home_widgets/water_widget_sync.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/widgets/animated_count_text.dart';
import 'package:fastingapp/core/widgets/day_switch_transition.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/domain/trackers/water_store.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:fastingapp/presentation/water/reminder/water_reminder_result.dart';
import 'package:fastingapp/presentation/water/water_glass_icons.dart';
import 'package:fastingapp/presentation/water/water_units.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/water_view_mixin.dart';

/// Header bandı — cetvel bunun altından başlar (AppBar’da çizgi yok).
const _kWaterHeaderHeight = 56.0;
const _kWaterRulerWidth = 36.0;

/// Su takip detay — animasyonlu su seviyesi, baloncuklar, dalgıç mascot.
final class WaterView extends StatefulWidget {
  const WaterView({this.initialMl = 0, this.dailyGoalMl = 2500, super.key});

  final int initialMl;
  final int dailyGoalMl;

  @override
  State<WaterView> createState() => _WaterViewState();
}

class _WaterViewState extends State<WaterView>
    with TickerProviderStateMixin, WaterViewMixin {
  @override
  void initState() {
    super.initState();
    initWaterControllers();
    unawaited(bootstrapWaterDay());
  }

  @override
  void dispose() {
    disposeWaterControllers();
    super.dispose();
  }

  /// Cetvel yalnızca görünen su dalgasının üstünde.
  Widget _buildRulerAboveWater(
    BuildContext context,
    double waterHeight, {
    required double opacity,
  }) {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    const waveSurfaceRatio = 0.18;
    const waveAmplitude = 10.0;
    final visualWaterTop = waterHeight <= 0
        ? 0.0
        : waterHeight * (1 - waveSurfaceRatio) + waveAmplitude;
    final height = math.max<double>(
      0,
      media.size.height - visualWaterTop - top,
    );

    if (opacity <= 0) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      top: top,
      width: _kWaterRulerWidth,
      height: height,
      child: Opacity(
        opacity: opacity,
        child: const IgnorePointer(child: _WaterRuler()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorWhite,
        // Sayfa yalnızca dolum / kutlama animasyonunda yeniden kurulur; sürekli
        // dönen dalga, balon ve maskot salınımı kendi küçük builder'larında.
        body: AnimatedBuilder(
          animation: Listenable.merge([fillController, celebrationController]),
          builder: (context, _) {
            final fill = fillAnimation.value.clamp(0.0, 1.0);
            final screenH = MediaQuery.sizeOf(context).height;
            final screenW = MediaQuery.sizeOf(context).width;
            final celebrationTValue = Curves.easeInOutCubic.transform(
              celebrationT.clamp(0.0, 1.0),
            );
            final waterH = screenH * fill;

            const middleFill = 0.5;
            final mascotBottomPad = bottom + 210;
            // Su gövdeye gelmeden çıkmasın (kafa kuruda kalmasın).
            final minWaterForMascot =
                mascotBottomPad + _WaterMascot.height * 0.45;
            final waterReachedMascot =
                waterH >= minWaterForMascot || celebrationTValue > 0.01;

            // Sağdan yavaş giriş — su geldikten sonra uzun bir fill aralığında.
            final entryStartFill = (minWaterForMascot / screenH).clamp(
              0.05,
              0.95,
            );
            final entryEndFill = (entryStartFill + 0.36).clamp(0.1, 1.0);
            final entrySpan = math.max(0.08, entryEndFill - entryStartFill);
            final entryT = Curves.easeOutCubic.transform(
              ((fill - entryStartFill) / entrySpan).clamp(0.0, 1.0),
            );

            final showDiver =
                waterReachedMascot &&
                (fill >= middleFill || celebrationTValue > 0.01);
            final showHi = waterReachedMascot && !showDiver && entryT > 0.001;
            final showMascot = showHi || showDiver;

            final mascotLift = celebrationTValue * (screenH * 0.07);
            final mascotScale = lerpDouble(1.0, 1.32, celebrationTValue) ?? 1.0;
            final pageBgOpacity = 1 - celebrationTValue;
            final immersive = celebrationTValue >= 0.999;

            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: pageBgOpacity,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ColorName.colorWhite,
                          ColorName.colorWaterPageFade,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: waterH,
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        waveController,
                        bubbleController,
                      ]),
                      builder: (context, _) => _WaterBody(
                        wavePhase: waveController.value * math.pi * 2,
                        bubblePhase: bubbleController.value,
                        celebrationT: celebrationTValue,
                        bubbles: _spawnedBubbles,
                      ),
                    ),
                  ),
                ),
                // Clip yok — kafa kesilmesin; su gelince sağdan yavaş girer.
                if (showMascot)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: mascotBottomPad,
                    child: AnimatedBuilder(
                      animation: mascotBobController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(
                          0,
                          -mascotLift +
                              math.sin(mascotBobController.value * math.pi) *
                                  10,
                        ),
                        child: child,
                      ),
                      child: RepaintBoundary(
                        child: Transform.scale(
                          scale: mascotScale,
                          alignment: Alignment.bottomCenter,
                          child: _WaterMascot(
                            showDiver: showDiver,
                            entryT: math.max(entryT, celebrationTValue),
                            screenWidth: screenW,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!immersive)
                  _buildRulerAboveWater(
                    context,
                    waterH,
                    opacity: 1 - celebrationTValue,
                  ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: _kWaterHeaderHeight,
                        width: double.infinity,
                        child: _WaterHeader(
                          onBack: () => context.pop(),
                          onReminder: openReminder,
                          dateLabel: waterDateLabel(context),
                          onDateTap: onWaterDateTapped,
                          onPrevDay: onWaterPrevDay,
                          onNextDay: onWaterNextDay,
                          canGoPrev: canGoPrevWaterDay,
                          canGoNext: canGoNextWaterDay,
                          dayNavDirection: dayNavDirection,
                          selectedDate: selectedDate,
                        ),
                      ),
                      Expanded(
                        child: DaySwitchTransition(
                          date: selectedDate,
                          direction: dayNavDirection,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                lerpDouble(48, 16, celebrationTValue) ?? 48,
                                8,
                                lerpDouble(24, 16, celebrationTValue) ?? 24,
                                0,
                              ),
                              child: _WaterStats(
                                currentMl: currentMl,
                                dailyGoalMl: dailyGoalMl,
                                unit: _waterUnit,
                                celebrationT: celebrationTValue,
                                onEditGoal: isWaterToday ? editDailyGoal : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 0,
                  bottom: bottom + 16,
                  child: IgnorePointer(
                    ignoring: !isWaterToday,
                    child: AnimatedOpacity(
                      opacity: isWaterToday ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: _WaterControls(
                        addMl: addMl,
                        unit: _waterUnit,
                        onAdd: addWater,
                        onRemove: removeWater,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _WaterHeader extends StatelessWidget {
  const _WaterHeader({
    required this.onBack,
    required this.onReminder,
    required this.dateLabel,
    required this.onDateTap,
    required this.onPrevDay,
    required this.onNextDay,
    required this.canGoPrev,
    required this.canGoNext,
    required this.dayNavDirection,
    required this.selectedDate,
  });

  final VoidCallback onBack;
  final VoidCallback onReminder;
  final String dateLabel;
  final VoidCallback onDateTap;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final bool canGoPrev;
  final bool canGoNext;
  final int dayNavDirection;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final chevronIdle = ColorName.colorTitle.withValues(alpha: 0.35);
    final chevronDisabled = ColorName.colorTitle.withValues(alpha: 0.15);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 16, 0),
      child: Row(
        children: [
          _CircleIconButton(onTap: onBack, child: _backIcon()),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DayChevron(
                  icon: Icons.chevron_left_rounded,
                  enabled: canGoPrev,
                  enabledColor: chevronIdle,
                  disabledColor: chevronDisabled,
                  onTap: onPrevDay,
                ),
                GestureDetector(
                  onTap: onDateTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: DaySwitchTransition(
                      date: selectedDate,
                      direction: dayNavDirection,
                      child: Text(dateLabel, style: AppTextStyles.waterToday),
                    ),
                  ),
                ),
                _DayChevron(
                  icon: Icons.chevron_right_rounded,
                  enabled: canGoNext,
                  enabledColor: chevronIdle,
                  disabledColor: chevronDisabled,
                  onTap: onNextDay,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _CircleIconButton(
            onTap: onReminder,
            child: Assets.icons.solarBellBingLineDuotone.svg(
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                ColorName.colorTitle,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backIcon() {
    return Assets.icons.solarAltArrowUpLineDuotone.svg(
      width: 20,
      height: 20,
      colorFilter: const ColorFilter.mode(
        ColorName.colorTitle,
        BlendMode.srcIn,
      ),
    );
  }
}

final class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      shadowColor: ColorName.colorBlack.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}

final class _DayChevron extends StatelessWidget {
  const _DayChevron({
    required this.icon,
    required this.enabled,
    required this.enabledColor,
    required this.disabledColor,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color enabledColor;
  final Color disabledColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: enabled ? enabledColor : disabledColor),
        ),
      ),
    );
  }
}

final class _WaterStats extends StatelessWidget {
  const _WaterStats({
    required this.currentMl,
    required this.dailyGoalMl,
    required this.unit,
    required this.celebrationT,
    this.onEditGoal,
  });

  final int currentMl;
  final int dailyGoalMl;

  /// `ml` | `oz` (yalnızca gösterim).
  final String unit;
  final double celebrationT;
  final VoidCallback? onEditGoal;

  @override
  Widget build(BuildContext context) {
    final t = celebrationT.clamp(0.0, 1.0);
    final heroStyle = TextStyle.lerp(
      AppTextStyles.waterHeroAmount,
      AppTextStyles.waterHeroAmount.copyWith(color: ColorName.colorWaterAction),
      t,
    )!;
    final unitStyle = TextStyle.lerp(
      AppTextStyles.waterUnit,
      AppTextStyles.waterUnit.copyWith(color: ColorName.colorWaterAction),
      t,
    )!;
    final targetStyle = TextStyle.lerp(
      AppTextStyles.waterDailyTarget,
      AppTextStyles.waterDailyTarget.copyWith(
        color: ColorName.colorWaterAction.withValues(alpha: 0.65),
      ),
      t,
    )!;
    final targetBoldStyle = TextStyle.lerp(
      AppTextStyles.waterDailyTargetBold,
      AppTextStyles.waterDailyTargetBold.copyWith(
        color: ColorName.colorWaterAction,
      ),
      t,
    )!;

    return Column(
      children: [
        Opacity(
          opacity: t,
          child: Column(
            children: [
              Text(
                'water_page.goal_achieved'.tr(),
                style: AppTextStyles.waterGoalAchieved,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedCountText(
              value: currentMl,
              style: heroStyle,
              format: (n) => WaterUnits.amount(n, unit),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(WaterUnits.label(unit), style: unitStyle),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'water_page.daily_target_prefix'.tr(),
                      style: targetStyle,
                    ),
                    TextSpan(
                      text: WaterUnits.withUnit(dailyGoalMl, unit),
                      style: targetBoldStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    ignoring: t > 0.01,
                    child: Opacity(
                      opacity: 1 - t,
                      child: GestureDetector(
                        onTap: onEditGoal,
                        behavior: HitTestBehavior.opaque,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            ColorName.colorWaterAction,
                            BlendMode.srcIn,
                          ),
                          child: AppImages.solarPenBold.image(
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: t < 0.99,
                    child: Opacity(
                      opacity: t,
                      child: AppImages.solarVerifiedCheckBold.image(
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _WaterRuler extends StatelessWidget {
  const _WaterRuler();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _WaterRulerPainter(),
          size: Size(_kWaterRulerWidth, constraints.maxHeight),
        );
      },
    );
  }
}

final class _WaterRulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ColorName.colorWaterRulerTick
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const tickGap = 8.0;
    const stride = tickGap;
    var y = 0.0;
    var i = 0;

    while (y <= size.height) {
      final w = i.isEven ? 19.0 : 11.0;
      canvas.drawLine(Offset(8, y), Offset(8 + w, y), paint);
      i++;
      y += stride;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Su seviyesine göre "hi" veya dalgıç — aynı anda yalnızca biri.
final class _WaterMascot extends StatelessWidget {
  const _WaterMascot({
    required this.showDiver,
    required this.entryT,
    required this.screenWidth,
  });

  final bool showDiver;
  final double entryT;
  final double screenWidth;

  static const height = 220.0;

  @override
  Widget build(BuildContext context) {
    // Ekran dışından (sağ) yavaşça içeri — entryT 0→1.
    final entryDx =
        lerpDouble(screenWidth * 0.72, screenWidth * 0.04, entryT) ?? 0;

    final image = showDiver
        ? AppImages.mascotDiver.image(
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          )
        : AppImages.mascotHiWater.image(
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          );

    // Clip/SizedBox yok — kafa ve snorkel kesilmesin.
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(entryDx, 0),
        child: showDiver
            ? Transform.rotate(angle: 15 * math.pi / 180, child: image)
            : image,
      ),
    );
  }
}

final class _SpawnedBubble {
  const _SpawnedBubble({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.kind,
    required this.phase,
  });

  final int id;
  final double x;

  /// 0 = dibe yakın, 1 = su yüzeyine yakın.
  final double y;
  final double size;
  final _BubbleKind kind;

  /// Bağımsız salınım ofseti (0–1).
  final double phase;
}

final class _WaterBody extends StatelessWidget {
  const _WaterBody({
    required this.wavePhase,
    required this.bubblePhase,
    required this.bubbles,
    this.celebrationT = 0,
  });

  final double wavePhase;
  final double bubblePhase;
  final List<_SpawnedBubble> bubbles;
  final double celebrationT;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final t = celebrationT.clamp(0.0, 1.0);
    final waveSurface = lerpDouble(0.18, 0.02, t) ?? 0.18;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final waterH = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: 1 - t,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _WaterWavePainter(
                        color: ColorName.colorWaterWaveDeep,
                        phase: wavePhase,
                        amplitude: 10,
                        surfaceRatio: waveSurface,
                      ),
                    ),
                    CustomPaint(
                      painter: _WaterWavePainter(
                        color: ColorName.colorWaterWaveLight,
                        phase: wavePhase + 0.8,
                        amplitude: 7,
                        surfaceRatio: waveSurface + 0.04,
                      ),
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: t,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ColorName.colorWaterWaveLight,
                        ColorName.colorWaterWaveDeep,
                      ],
                    ),
                  ),
                ),
              ),
              ...bubbles.map((b) {
                // Yumuşak salınım — modulo yok, ani yer değişimi olmaz.
                final drift =
                    math.sin((bubblePhase + b.phase) * math.pi * 2) * 8;
                final bob =
                    math.sin(
                      (bubblePhase * 1.35 + b.phase + b.y) * math.pi * 2,
                    ) *
                    5;
                final maxBottom = math.max(8.0, waterH - b.size - 10);
                final bottom = (8 + b.y * (maxBottom - 8) + bob).clamp(
                  8.0,
                  maxBottom,
                );
                return Positioned(
                  left: width * b.x + drift - b.size / 2,
                  bottom: bottom,
                  child: _PoppingWaterBubble(
                    key: ValueKey(b.id),
                    size: b.size,
                    kind: b.kind,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

enum _BubbleKind { type1, type2 }

/// Yeni balon — küçükten büyüyerek belirir.
final class _PoppingWaterBubble extends StatefulWidget {
  const _PoppingWaterBubble({
    required super.key,
    required this.size,
    required this.kind,
  });

  final double size;
  final _BubbleKind kind;

  @override
  State<_PoppingWaterBubble> createState() => _PoppingWaterBubbleState();
}

class _PoppingWaterBubbleState extends State<_PoppingWaterBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _pop = CurvedAnimation(parent: _popController, curve: Curves.easeOutBack);
    _popController.forward();
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        return Opacity(
          opacity: _pop.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.35 + 0.65 * _pop.value, child: child),
        );
      },
      // Bulanık katmanlar her karede yeniden çizilmesin (yalnızca konum değişir).
      child: RepaintBoundary(
        child: _WaterBubble(size: widget.size, kind: widget.kind),
      ),
    );
  }
}

/// Tip 1: yumuşak glow + highlight + gradient rim (iç içe).
/// Tip 2: soft glow + ince halkalar.
final class _WaterBubble extends StatelessWidget {
  const _WaterBubble({required this.size, required this.kind});

  final double size;
  final _BubbleKind kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _BubbleKind.type1 => _Type1Bubble(size: size),
      _BubbleKind.type2 => _Type2Bubble(size: size),
    };
  }
}

/// Figma tip 1 — ~28px referans; scale ile büyütülür.
final class _Type1Bubble extends StatelessWidget {
  const _Type1Bubble({required this.size});

  final double size;

  static const _ref = 28.0;

  @override
  Widget build(BuildContext context) {
    final s = size / _ref;
    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: -51.21 * math.pi / 180,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Dış soft glow
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5.06 * s, sigmaY: 5.06 * s),
              child: Container(
                width: size * 1.05,
                height: size * 1.05,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorName.colorWhite.withValues(alpha: 0.18),
                ),
              ),
            ),
            // Rim: fill %33 + gradient stroke
            CustomPaint(
              size: Size(size, size),
              painter: _BubbleRimPainter(
                strokeWidth: 1.27 * s,
                fillAlpha: 0.33,
              ),
            ),
            // Üst highlight (Ellipse 22)
            Positioned(
              top: 7.12 * s,
              left: 13.03 * s,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 2.53 * s,
                  sigmaY: 2.53 * s,
                ),
                child: Container(
                  width: 11.39 * s,
                  height: 10.12 * s,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorName.colorWhite,
                  ),
                ),
              ),
            ),
            // İç soft blob
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3.2 * s, sigmaY: 3.2 * s),
              child: Align(
                alignment: const Alignment(0, -0.25),
                child: Container(
                  width: size * 0.42,
                  height: size * 0.42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorName.colorWhite.withValues(alpha: 0.55),
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

/// Figma tip 2 — soft glow + iç içe ince halkalar + küçük çekirdek.
final class _Type2Bubble extends StatelessWidget {
  const _Type2Bubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: size * 0.12,
              sigmaY: size * 0.12,
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorName.colorWhite.withValues(alpha: 0.22),
              ),
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: const _BubbleRingsPainter(),
          ),
          Container(
            width: size * (9 / 28),
            height: size * (9 / 28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorName.colorWhite.withValues(alpha: 0.33),
            ),
          ),
        ],
      ),
    );
  }
}

final class _BubbleRimPainter extends CustomPainter {
  _BubbleRimPainter({required this.strokeWidth, required this.fillAlpha});

  final double strokeWidth;
  final double fillAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - strokeWidth / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = ColorName.colorWhite.withValues(alpha: fillAlpha),
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColorName.colorWhite, Color(0x00FFFFFF)],
      ).createShader(rect);

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BubbleRimPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fillAlpha != fillAlpha;
  }
}

final class _BubbleRingsPainter extends CustomPainter {
  const _BubbleRingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, size.width * 0.04)
      ..color = ColorName.colorWhite.withValues(alpha: 0.45);

    for (final ratio in [0.92, 0.68, 0.48]) {
      canvas.drawCircle(center, size.shortestSide / 2 * ratio, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final class _WaterWavePainter extends CustomPainter {
  _WaterWavePainter({
    required this.color,
    required this.phase,
    this.amplitude = 8,
    this.surfaceRatio = 0.18,
  });

  final Color color;
  final double phase;
  final double amplitude;
  final double surfaceRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final baseY = size.height * surfaceRatio;

    path.moveTo(-40, size.height);
    path.lineTo(-40, baseY);

    for (var x = -40.0; x <= size.width + 40; x += 4) {
      final y =
          baseY + math.sin((x / size.width * math.pi * 2) + phase) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width + 40, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

final class _WaterControls extends StatelessWidget {
  const _WaterControls({
    required this.addMl,
    required this.unit,
    required this.onAdd,
    required this.onRemove,
  });

  final int addMl;
  final String unit;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: _WaterPlusButton(addMl: addMl, unit: unit, onTap: onAdd),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _WaterActionCircle(
                size: _WaterActionCircle.minusSize,
                onTap: onRemove,
                child: Assets.icons.icRoundMinus.svg(
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    ColorName.colorWhite,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              _WaterBottleButton(glassSizeMl: addMl),
            ],
          ),
        ],
      ),
    );
  }
}

final class _WaterPlusButton extends StatelessWidget {
  const _WaterPlusButton({
    required this.addMl,
    required this.unit,
    required this.onTap,
  });

  final int addMl;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WaterActionCircle(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Assets.icons.uilPlus.svg(
            width: 40,
            height: 40,
            colorFilter: const ColorFilter.mode(
              ColorName.colorWhite,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            WaterUnits.withUnit(addMl, unit),
            style: AppTextStyles.waterAddLabel,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

final class _WaterActionCircle extends StatelessWidget {
  const _WaterActionCircle({
    required this.onTap,
    required this.child,
    this.size = plusSize,
  });

  /// Figma + : 90×90 — Figma − : 56×56; padding 10/14, border, inner shadow aynı.
  static const plusSize = 90.0;
  static const minusSize = 56.0;
  static const _padding = EdgeInsets.fromLTRB(10, 14, 10, 14);

  final VoidCallback onTap;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorName.colorWaterAction,
            border: Border.all(
              color: ColorName.colorWhite.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorName.colorWhite.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 4),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: Padding(
            padding: _padding,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

final class _WaterBottleButton extends StatelessWidget {
  const _WaterBottleButton({required this.glassSizeMl});

  final int glassSizeMl;

  /// Figma: 56×56, #FFFFFF, çift drop shadow (Black/100 %5 + Black/200 %10).
  static const _size = 56.0;
  static const _shadowColor = Color(0xFF0C0C0D);

  @override
  Widget build(BuildContext context) {
    final icon = WaterGlassIcons.forMl(glassSizeMl);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ColorName.colorWhite,
          boxShadow: [
            BoxShadow(
              color: _shadowColor.withValues(alpha: 0.05),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
            BoxShadow(
              color: _shadowColor.withValues(alpha: 0.10),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: ClipOval(
          child: Transform.scale(
            scale: 1.32,
            child: icon.image(width: 40, height: 40, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
