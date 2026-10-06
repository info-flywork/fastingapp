import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/presentation/mochi_world/model/mochi_world_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Adadaki tek bir element: zıplayarak belirir (parıltı patlamasıyla),
/// küçülerek kaybolur, türü değişince (ör. ağaç → solgun ağaç) yerinde
/// dönüşür ve görünürken türüne özel boşta animasyonu oynar — ağaç/çiçek
/// salınır, fener parlar, şelale akar, gölet ışıldar.
///
/// Genişliği üst [AnimatedPositioned]'dan alır; alt-orta noktası zemine
/// basar.
final class MochiIslandElement extends StatefulWidget {
  const MochiIslandElement({
    required this.placement,
    required this.shown,
    required this.clock,
    this.delay = Duration.zero,
    super.key,
  });

  final MochiPlacement placement;
  final bool shown;
  final ValueListenable<double> clock;

  /// Belirmeden önce beklenecek süre (aynı anda gelenler sırayla zıplasın).
  final Duration delay;

  @override
  State<MochiIslandElement> createState() => _MochiIslandElementState();
}

class _MochiIslandElementState extends State<MochiIslandElement>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
    reverseDuration: const Duration(milliseconds: 420),
  );

  Timer? _delayTimer;

  /// Belirme: yaylı büyüme animasyonun ilk %70'inde biter.
  static const _grow = Interval(0, 0.7, curve: Curves.easeOutBack);

  @override
  void initState() {
    super.initState();
    if (widget.shown) _appear();
  }

  @override
  void didUpdateWidget(covariant MochiIslandElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shown == widget.shown) return;
    if (widget.shown) {
      _appear();
    } else {
      _delayTimer?.cancel();
      _pop.reverse();
    }
  }

  void _appear() {
    _delayTimer?.cancel();
    if (widget.delay == Duration.zero) {
      _pop.forward();
      return;
    }
    _delayTimer = Timer(widget.delay, () {
      if (mounted && widget.shown) _pop.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placement = widget.placement;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w * placement.kind.aspect;
        final body = _ElementBody(
          placement: placement,
          clock: widget.clock,
          width: w,
          height: h,
          cacheWidth: (w * dpr).ceil(),
        );

        return SizedBox(
          width: w,
          height: h,
          child: AnimatedBuilder(
            animation: _pop,
            child: body,
            builder: (context, child) {
              final p = _pop.value;
              if (p <= 0) return const SizedBox.shrink();
              final v = _grow.transform(p);
              final appearing = _pop.status == AnimationStatus.forward;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: v,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  ),
                  // Belirirken tabandan saçılan parıltılar.
                  if (appearing && !placement.decal)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _BurstPainter(
                            progress: p,
                            seed: placement.key.hashCode,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ───────────────────────────── Gövde ─────────────────────────────

final class _ElementBody extends StatelessWidget {
  const _ElementBody({
    required this.placement,
    required this.clock,
    required this.width,
    required this.height,
    required this.cacheWidth,
  });

  final MochiPlacement placement;
  final ValueListenable<double> clock;
  final double width;
  final double height;
  final int cacheWidth;

  /// Kuru sprite'ı olmayan solmuş elementler: renk soluklaşır, sıcak gri.
  static const _fade = ColorFilter.matrix([
    0.62, 0.30, 0.08, 0, 6, //
    0.22, 0.66, 0.12, 0, 2, //
    0.20, 0.30, 0.42, 0, -4, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final kind = placement.kind;
    final phase = (placement.key.hashCode % 1000) / 1000 * math.pi * 2;

    final shadowStrength = switch (kind) {
      _ when placement.decal || kind.isPond || kind.isSingleFlower => 0.0,
      MochiElementKind.flowers => 0.5,
      MochiElementKind.shrubDry => 0.6,
      _ => 1.0,
    };

    // Tür ya da solma değişince sprite yerinde dönüşür.
    final sprite = AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(animation),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: _Sprite(
        key: ValueKey((kind, placement.faded)),
        kind: kind,
        faded: placement.faded,
        flip: placement.flip,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Temas gölgesi: elementi zemine oturtur.
        if (shadowStrength > 0)
          Positioned(
            left: width * 0.1,
            right: width * 0.1,
            bottom: -width * 0.05,
            height: width * 0.14,
            child: CustomPaint(
              painter: _ContactShadowPainter(strength: shadowStrength),
            ),
          ),
        _IdleMotion(kind: kind, clock: clock, phase: phase, child: sprite),
        if (_overlayFor(kind, phase) case final painter?)
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: painter)),
          ),
      ],
    );
  }

  CustomPainter? _overlayFor(MochiElementKind kind, double phase) =>
      switch (kind) {
        MochiElementKind.waterfall => _WaterfallPainter(
          clock: clock,
          faded: placement.faded,
        ),
        MochiElementKind.pondLily => _GlintPainter(clock: clock, phase: phase),
        MochiElementKind.pondDrying => _GlintPainter(
          clock: clock,
          phase: phase,
          spots: _GlintPainter.puddle,
          strength: 0.45,
        ),
        MochiElementKind.lantern => _LanternGlowPainter(
          clock: clock,
          phase: phase,
        ),
        _ => null,
      };
}

final class _Sprite extends StatelessWidget {
  const _Sprite({
    required this.kind,
    required this.faded,
    required this.flip,
    required this.width,
    required this.height,
    required this.cacheWidth,
    super.key,
  });

  final MochiElementKind kind;
  final bool faded;
  final bool flip;
  final double width;
  final double height;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    var image = appImage(
      kind.asset,
      width: width,
      height: height,
      fit: BoxFit.fill,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    if (flip) image = Transform.flip(flipX: true, child: image);
    if (faded)
      image = ColorFiltered(colorFilter: _ElementBody._fade, child: image);
    return image;
  }
}

/// Türe göre boşta hareket: ağaç/çiçek tabandan salınır; kuru olanlar
/// daha az ve daha ağır.
final class _IdleMotion extends StatelessWidget {
  const _IdleMotion({
    required this.kind,
    required this.clock,
    required this.phase,
    required this.child,
  });

  final MochiElementKind kind;
  final ValueListenable<double> clock;
  final double phase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // (salınım genliği, hız)
    final (amp, speed) = switch (kind) {
      MochiElementKind.treeBare => (0.010, 0.6),
      MochiElementKind.treePale ||
      MochiElementKind.saplingWilting => (0.020, 0.7),
      _ when kind.isHealthyTree => (0.028, 0.9),
      MochiElementKind.flowerWilted => (0.025, 0.8),
      _ when kind.isSingleFlower => (0.06, 1.6),
      MochiElementKind.flowers => (0.045, 1.5),
      MochiElementKind.shrubDry => (0.015, 0.7),
      _ => (0.0, 0.0),
    };
    if (amp == 0) return child;

    return AnimatedBuilder(
      animation: clock,
      child: child,
      builder: (context, child) {
        final t = clock.value;
        // Rüzgârda tepe sallanır, taban sabit; ağaçlarda hafif nefes.
        final m = Matrix4.skewX(math.sin(t * speed + phase) * amp);
        if (kind.isTree) {
          m.scaleByDouble(1, 1 + math.sin(t * 1.3 + phase) * 0.008, 1, 1);
        }
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: m,
          child: child,
        );
      },
    );
  }
}

// ───────────────────────────── Ressamlar ─────────────────────────────

final class _ContactShadowPainter extends CustomPainter {
  const _ContactShadowPainter({required this.strength});

  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromRGBO(40, 50, 20, 0.28 * strength)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.35);
    canvas.drawOval(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ContactShadowPainter old) =>
      old.strength != strength;
}

/// Belirme anında tabandan dışa saçılan parıltı ve yaprak tozları.
final class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress, required this.seed});

  final double progress;
  final int seed;

  static const _colors = [
    Color(0xFFFFF3B0),
    Color(0xFFB8E986),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = ((progress - 0.08) / 0.92).clamp(0.0, 1.0);
    if (p <= 0 || p >= 1) return;
    final rnd = math.Random(seed);
    final origin = Offset(size.width / 2, size.height * 0.85);
    final reach = math.max(size.width, 40.0) * 0.75;
    final fade = 1 - Curves.easeIn.transform(p);
    final travel = Curves.easeOutCubic.transform(p);
    for (var i = 0; i < 12; i++) {
      // Yukarı yarım daireye doğru saçıl.
      final a = math.pi + rnd.nextDouble() * math.pi;
      final d = reach * (0.45 + rnd.nextDouble() * 0.55) * travel;
      final pos = origin + Offset(math.cos(a) * d, math.sin(a) * d * 0.8);
      final color = _colors[i % _colors.length].withValues(alpha: 0.9 * fade);
      final r = (1.8 + rnd.nextDouble() * 2.6) * (0.6 + 0.4 * fade);
      final paint = Paint()..color = color;
      if (i.isEven) {
        _sparkle(canvas, pos, r * 1.8, paint);
      } else {
        canvas.drawCircle(pos, r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.progress != progress;
}

/// Şelale: iki çağlayan boyunca aşağı akan köpük çizgileri, dipte köpük
/// ve havuzdan yükselen sis. Solmuşken su daha bulanık.
final class _WaterfallPainter extends CustomPainter {
  _WaterfallPainter({required this.clock, required this.faded})
    : super(repaint: clock);

  final ValueListenable<double> clock;
  final bool faded;

  // Sprite'a göre çağlayan dikdörtgenleri (0..1).
  static const _falls = [
    Rect.fromLTRB(0.47, 0.12, 0.58, 0.36),
    Rect.fromLTRB(0.49, 0.50, 0.60, 0.69),
  ];
  static const _pool = Offset(0.57, 0.77);

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final strength = faded ? 0.55 : 1.0;
    final streak = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, size.width * 0.012);
    for (var f = 0; f < _falls.length; f++) {
      final r = _falls[f];
      final rect = Rect.fromLTRB(
        r.left * size.width,
        r.top * size.height,
        r.right * size.width,
        r.bottom * size.height,
      );
      const lanes = 6;
      for (var i = 0; i < lanes; i++) {
        final x = rect.left + rect.width * (i + 0.5) / lanes;
        final speed = 1.1 + (i % 3) * 0.25;
        final y = (t * speed + i * 0.37 + f * 0.5) % 1.0;
        final len = rect.height * 0.28;
        final y0 = rect.top + y * rect.height;
        final alpha = math.sin(y * math.pi);
        streak.color = Colors.white.withValues(alpha: 0.55 * alpha * strength);
        canvas.drawLine(
          Offset(x, y0),
          Offset(x, math.min(rect.bottom, y0 + len)),
          streak,
        );
      }
      // Çağlayanın dibinde kaynayan köpük.
      final foam = Paint()
        ..color = Colors.white.withValues(alpha: 0.7 * strength);
      for (var i = 0; i < 5; i++) {
        final fx = rect.left + rect.width * (0.1 + 0.2 * i);
        final bob = math.sin(t * 6 + i * 1.7 + f) * size.width * 0.008;
        canvas.drawCircle(
          Offset(fx, rect.bottom + bob),
          size.width * (0.012 + 0.006 * math.sin(t * 4 + i)).abs(),
          foam,
        );
      }
    }
    // Havuzdan yükselen sis.
    final mist = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.03);
    for (var i = 0; i < 4; i++) {
      final m = (t * 0.25 + i / 4) % 1.0;
      final c = Offset(
        (_pool.dx + math.sin(t + i) * 0.05) * size.width,
        (_pool.dy - m * 0.22) * size.height,
      );
      mist.color = Colors.white.withValues(alpha: 0.35 * (1 - m) * strength);
      canvas.drawCircle(c, size.width * (0.05 + m * 0.05), mist);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterfallPainter old) => old.faded != faded;
}

/// Gölet yüzeyinde yanıp sönen ışık pırıltıları.
final class _GlintPainter extends CustomPainter {
  _GlintPainter({
    required this.clock,
    required this.phase,
    this.spots = lilyPond,
    this.strength = 1,
  }) : super(repaint: clock);

  final ValueListenable<double> clock;
  final double phase;
  final List<Offset> spots;
  final double strength;

  /// Nilüferli göletin su yüzeyi (sprite'a göre 0..1).
  static const lilyPond = [
    Offset(0.27, 0.50),
    Offset(0.38, 0.62),
    Offset(0.45, 0.38),
    Offset(0.66, 0.42),
    Offset(0.72, 0.60),
    Offset(0.56, 0.68),
    Offset(0.33, 0.40),
  ];

  /// Kuruyan göletin ortasında kalan su birikintisi.
  static const puddle = [
    Offset(0.42, 0.52),
    Offset(0.58, 0.46),
    Offset(0.50, 0.60),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    for (var i = 0; i < spots.length; i++) {
      // Her pırıltı kendi ritminde kısa bir an parlar.
      final w = math.max(0.0, math.sin(t * 1.7 + i * 2.1 + phase));
      final glow = w * w * w * strength;
      if (glow < 0.02) continue;
      final c = Offset(spots[i].dx * size.width, spots[i].dy * size.height);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
      _sparkle(canvas, c, size.width * 0.028 * (0.5 + 0.5 * glow), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlintPainter old) => false;
}

/// Fenerin camında titreşen sıcak ışık ve çevresine vuran hâle.
final class _LanternGlowPainter extends CustomPainter {
  _LanternGlowPainter({required this.clock, required this.phase})
    : super(repaint: clock);

  final ValueListenable<double> clock;
  final double phase;

  static const _glass = Offset(0.31, 0.50);

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    // İki farklı ritim üst üste: alev gibi düzensiz titreme.
    final flicker =
        0.5 +
        0.3 * math.sin(t * 2.3 + phase) +
        0.2 * math.sin(t * 7.1 + phase * 2);
    final c = Offset(_glass.dx * size.width, _glass.dy * size.height);
    final r = size.width * (1.1 + 0.15 * flicker);
    final halo = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(c, r, [
        Color.fromRGBO(255, 200, 110, 0.30 + 0.25 * flicker),
        const Color.fromRGBO(255, 200, 110, 0),
      ]);
    canvas.drawCircle(c, r, halo);
  }

  @override
  bool shouldRepaint(covariant _LanternGlowPainter old) => false;
}

/// Dört kollu yumuşak yıldız pırıltısı.
void _sparkle(Canvas canvas, Offset c, double r, Paint paint) {
  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
    ..close();
  canvas.drawPath(path, paint);
}
