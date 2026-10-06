import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:fastingapp/presentation/mochi_world/model/mochi_world_layout.dart';
import 'package:fastingapp/presentation/mochi_world/model/mochi_world_stage.dart';
import 'package:fastingapp/presentation/mochi_world/view/widgets/mochi_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Mochi World — yaşayan, yüzen ada. Ortaya dokununca tüm arayüz kaybolur ve
/// yalnızca animasyonlu arka plan kalır; o sürükleyici modda tüm dünya
/// durumları sırayla oynatılır.
final class MochiWorldView extends StatefulWidget {
  const MochiWorldView({super.key});

  @override
  State<MochiWorldView> createState() => _MochiWorldViewState();
}

class _MochiWorldViewState extends State<MochiWorldView>
    with SingleTickerProviderStateMixin {
  /// Tüm animasyonların beslendiği monotonik saat (saniye).
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  late final Ticker _ticker;

  /// Sürükleyici moddaki durum gösterisinin zamanlayıcısı.
  Timer? _demoTimer;
  static const _demoStep = Duration(milliseconds: 4500);

  bool _immersive = false;

  /// Gösteride ekrandaki durum ([kMochiDemoStates] indisi).
  int _demoIndex = 0;

  /// Sayfa açılınca ada boş başlar; hemen ardından kullanıcının adası
  /// elementleri sırayla zıplatarak büyür.
  bool _opened = false;
  Timer? _openTimer;

  bool _precached = false;

  /// Kullanıcının dünya ilerleyişi (0..1). TODO: gerçek veriden beslenecek.
  static const double _worldProgress = 0.12;

  /// Adanın sağlığı. TODO: aksatılan günlerden (seri kırılması) beslenecek.
  static const MochiHealth _health = MochiHealth.thriving;

  static final _zones = <_Zone>[
    _Zone(
      id: _ZoneId.forest,
      icon: Assets.images.forest,
      titleKey: 'mochi_world.forest',
      progressKey: 'mochi_world.forest_progress',
      current: 3,
      goal: 10,
    ),
    _Zone(
      id: _ZoneId.lake,
      icon: Assets.images.lake,
      titleKey: 'mochi_world.lake',
      progressKey: 'mochi_world.lake_progress',
      current: 2,
      goal: 7,
    ),
    _Zone(
      id: _ZoneId.summit,
      icon: Assets.images.summit,
      titleKey: 'mochi_world.summit',
      progressKey: 'mochi_world.summit_progress',
      current: 0,
      goal: 2,
    ),
    _Zone(
      id: _ZoneId.garden,
      icon: Assets.images.garden,
      titleKey: 'mochi_world.garden',
      progressKey: 'mochi_world.garden_progress',
      current: 3,
      goal: 10,
    ),
  ];

  _ZoneId _selected = _ZoneId.forest;

  _Zone get _active => _zones.firstWhere((z) => z.id == _selected);

  /// Her bölgenin ilerlemesine göre büyüme seviyesi.
  Map<MochiZone, int> get _dataLevels => {
    for (final z in _zones)
      MochiZone.values.byName(z.id.name): mochiZoneLevel(z.ratio),
  };

  /// Ekrandaki dünya: gösterideyse sıradaki referans durum, değilse
  /// kullanıcının kendi adası.
  ({Map<MochiZone, int> levels, MochiHealth health}) get _world {
    if (_immersive) {
      final s = kMochiDemoStates[_demoIndex];
      return (
        levels: {for (final z in MochiZone.values) z: s.level},
        health: s.health,
      );
    }
    return (levels: _opened ? _dataLevels : const {}, health: _health);
  }

  /// Sahnenin ruh hâli: ada büyüdükçe parıltılar artar, çiçeklerle
  /// kelebekler, ormanla kuşlar gelir; solunca hepsi çekilir.
  MochiWorldStage _stageFor(int level, MochiHealth health) {
    final thriving = health == MochiHealth.thriving;
    return MochiWorldStage(
      asset: mochiBaseAsset(level, health),
      weather: mochiWeather(level, health),
      lushness: thriving ? 0.15 + level * 0.2 : 0.05,
      butterflies: thriving && level >= 1,
      birds: thriving && level >= 3,
      rainbow: thriving && level >= kMochiMaxLevel,
    );
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _clock.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    })..start();
    _openTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _opened = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Belirme ve dönüşüm anında görsel çözülürken boş kare kalmasın.
    for (final kind in MochiElementKind.values) {
      precacheImage(AssetImage(kind.asset), context);
    }
    for (final (:level, :health) in kMochiDemoStates) {
      precacheImage(AssetImage(mochiBaseAsset(level, health)), context);
    }
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _openTimer?.cancel();
    _ticker.dispose();
    _clock.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _enterImmersive() {
    if (_immersive) return;
    HapticFeedback.lightImpact();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Kurak, boş adadan başla; referans sahneleri sırayla dolaş.
    setState(() {
      _immersive = true;
      _demoIndex = 0;
    });
    _demoTimer = Timer.periodic(_demoStep, (_) {
      if (!mounted) return;
      setState(() => _demoIndex = (_demoIndex + 1) % kMochiDemoStates.length);
    });
  }

  void _exitImmersive() {
    if (!_immersive) return;
    HapticFeedback.selectionClick();
    _demoTimer?.cancel();
    _demoTimer = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Kullanıcının gerçek adasına dön: fazlalar küçülür, eksikler gelir.
    setState(() => _immersive = false);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final world = _world;
    final level = world.levels.values.fold(0, math.max);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFB8D9F0),
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Yaşayan ada: elementler kullanıcı verisiyle şekillenir.
            Positioned.fill(
              child: MochiScene(
                stage: _stageFor(level, world.health),
                clock: _clock,
                placements: mochiCompose(world.levels, world.health),
              ),
            ),

            // ── Tüm ekranı kaplayan dokunma alanı: moda geçiş / çıkış.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _immersive ? _exitImmersive : _enterImmersive,
              ),
            ),

            // ── Arayüz katmanı (sürükleyici modda yumuşakça kaybolur).
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _immersive,
                child: AnimatedOpacity(
                  opacity: _immersive ? 0 : 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: _immersive ? 0.96 : 1,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: _Chrome(
                      top: top,
                      bottom: MediaQuery.paddingOf(context).bottom,
                      zones: _zones,
                      selected: _selected,
                      active: _active,
                      worldProgress: _worldProgress,
                      onSelect: (id) => setState(() => _selected = id),
                      onExplore: _enterImmersive,
                    ),
                  ),
                ),
              ),
            ),

            // ── Sürükleyici mod göstergeleri.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _immersive ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: _ImmersiveHud(
                    top: top,
                    bottom: MediaQuery.paddingOf(context).bottom,
                    index: _demoIndex,
                    count: kMochiDemoStates.length,
                  ),
                ),
              ),
            ),

            // ── Sürükleyici moddan çıkış düğmesi.
            if (_immersive)
              Positioned(
                top: top + 8,
                right: 12,
                child: _CircleIconButton(
                  onTap: _exitImmersive,
                  child: const Icon(Icons.close_rounded, size: 22),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Sürükleyici mod HUD ─────────────────────────

final class _ImmersiveHud extends StatelessWidget {
  const _ImmersiveHud({
    required this.top,
    required this.bottom,
    required this.index,
    required this.count,
  });

  final double top;
  final double bottom;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top + 16, bottom: bottom + 24),
      child: Column(
        children: [
          // Üstte nazik ipucu.
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                child: Text('mochi_world.immersive_hint'.tr(), style: _hud),
              ),
            ),
          ),
          const Spacer(),
          // Altta ilerleme noktaları.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: i == index ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: i == index ? 0.95 : 0.5,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Arayüz ─────────────────────────────

final class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.top,
    required this.bottom,
    required this.zones,
    required this.selected,
    required this.active,
    required this.worldProgress,
    required this.onSelect,
    required this.onExplore,
  });

  final double top;
  final double bottom;
  final List<_Zone> zones;
  final _ZoneId selected;
  final _Zone active;
  final double worldProgress;
  final ValueChanged<_ZoneId> onSelect;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottom > 0 ? bottom : 6.0;

    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _WeekCard(),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _WorldProgressCard(progress: worldProgress),
          ),
          Expanded(
            child: Align(
              alignment: const Alignment(0, 0.92),
              child: _ExploreHint(onTap: onExplore),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < zones.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _ZoneCard(
                      zone: zones[i],
                      selected: zones[i].id == selected,
                      onTap: () => onSelect(zones[i].id),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ZoneProgressCard(zone: active),
          ),
        ],
      ),
    );
  }
}

/// Ortadaki "dünyayı keşfet" ipucu — nazikçe nabız atar.
final class _ExploreHint extends StatefulWidget {
  const _ExploreHint({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ExploreHint> createState() => _ExploreHintState();
}

class _ExploreHintState extends State<_ExploreHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final v = Curves.easeInOut.transform(_c.value);
          return Transform.translate(
            offset: Offset(0, -6 * v),
            child: Opacity(opacity: 0.75 + 0.25 * v, child: child),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text('mochi_world.explore_hint'.tr(), style: _hud),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ZoneId { forest, lake, summit, garden }

@immutable
final class _Zone {
  const _Zone({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.progressKey,
    required this.current,
    required this.goal,
  });

  final _ZoneId id;
  final AssetGenImage icon;
  final String titleKey;
  final String progressKey;
  final int current;
  final int goal;

  double get ratio => goal <= 0 ? 0 : (current / goal).clamp(0.0, 1.0);
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CircleIconButton(
            onTap: () => context.go(RoutePaths.home.path),
            child: Transform.rotate(
              angle: math.pi,
              child: Assets.icons.solarAltArrowUpLineDuotoneRight.svg(
                width: 20,
                height: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'mochi_world.title'.tr(),
              textAlign: TextAlign.center,
              style: _title,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: ColorName.colorWhite,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text('mochi_world.level'.tr(args: ['1']), style: _level),
            ),
          ),
        ],
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}

final class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.radius = 16,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ColorName.colorBodyPageBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

final class _WeekCard extends StatelessWidget {
  const _WeekCard();

  static const _dayKeys = [
    'home.week_mon',
    'home.week_tue',
    'home.week_wed',
    'home.week_thu',
    'home.week_fri',
    'home.week_sat',
    'home.week_sun',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final selectedIndex = today.weekday - 1;

    return _GlassCard(
      radius: 12,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _WeekDay(
                dayKey: _dayKeys[i],
                date: monday.add(Duration(days: i)),
                selected: i == selectedIndex,
                hours: i == selectedIndex ? 10 : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.dayKey,
    required this.date,
    required this.selected,
    this.hours,
  });

  final String dayKey;
  final DateTime date;
  final bool selected;
  final int? hours;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = date.isAfter(today);

    final dayColor = selected
        ? ColorName.colorBrandStrong
        : ColorName.colorSubtitle.withValues(alpha: 0.5);
    final dateColor = selected || !isFuture
        ? ColorName.colorTitle
        : ColorName.colorSubtitle.withValues(alpha: 0.45);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? ColorName.colorWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ColorName.colorBlack.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayKey.tr(),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: AppTextStyles.homeWeekDay.copyWith(color: dayColor),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: AppTextStyles.homeWeekDate.copyWith(color: dateColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 18,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: hours != null
                ? ColorName.colorMealPositive
                : ColorName.colorBlack.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            hours != null ? 'home.week_hours'.tr(args: ['$hours']) : '-',
            style: hours != null
                ? AppTextStyles.homeWeekHours
                : AppTextStyles.homeWeekHours.copyWith(
                    color: ColorName.colorSubtitle.withValues(alpha: 0.6),
                  ),
          ),
        ),
      ],
    );
  }
}

final class _WorldProgressCard extends StatelessWidget {
  const _WorldProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Text('mochi_world.world_progress'.tr(), style: _sectionTitle),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: _sectionTitle.copyWith(color: ColorName.colorStepsFill),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(
            value: progress,
            fill: ColorName.colorStepsFill,
            track: ColorName.colorWhite,
          ),
        ],
      ),
    );
  }
}

final class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.selected,
    required this.onTap,
  });

  final _Zone zone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ColorName.colorWhite.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? ColorName.colorWhite : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            zone.icon.image(height: 40, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text(
              zone.titleKey.tr(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _zoneTitle,
            ),
            const SizedBox(height: 2),
            Text(
              zone.progressKey.tr(args: ['${zone.current}', '${zone.goal}']),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _zoneMeta,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ZoneProgressCard extends StatelessWidget {
  const _ZoneProgressCard({required this.zone});

  final _Zone zone;

  static const _fill = Color(0xFFA7CC65);
  static const _duration = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: _duration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    key: ValueKey('title-${zone.id}'),
                    child: Text(
                      zone.titleKey.tr(),
                      textAlign: TextAlign.left,
                      style: _sectionTitle,
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: _duration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: Text(
                  '${zone.current}/${zone.goal}',
                  key: ValueKey('count-${zone.id}'),
                  textAlign: TextAlign.right,
                  style: _sectionTitle.copyWith(color: _fill),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(
            value: zone.ratio,
            fill: _fill,
            track: ColorName.colorWhite,
          ),
        ],
      ),
    );
  }
}

final class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.fill,
    required this.track,
    this.duration = const Duration(milliseconds: 420),
  });

  final double value;
  final Color fill;
  final Color track;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99999),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0.0, 1.0)),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) {
                return FractionallySizedBox(
                  widthFactor: animated,
                  alignment: Alignment.centerLeft,
                  child: ColoredBox(color: fill),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

const _title = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 20,
  height: 1.2,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _level = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 14,
  height: 20 / 14,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _sectionTitle = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 14,
  height: 20 / 14,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _zoneTitle = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 14,
  height: 20 / 14,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _hud = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 13,
  height: 1.2,
  letterSpacing: -0.3,
  color: Colors.white,
);

final _zoneMeta = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 13,
  height: 16 / 13,
  letterSpacing: 13 * -0.015,
  color: ColorName.colorSubtitle.withValues(alpha: 0.6),
);
