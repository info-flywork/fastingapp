import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fastingapp/presentation/mochi_world/model/mochi_world_layout.dart';
import 'package:fastingapp/presentation/mochi_world/model/mochi_world_stage.dart';
import 'package:fastingapp/presentation/mochi_world/view/widgets/mochi_island_element.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Tek bir Mochi World sahnesi: tam ekran görsel + üstüne bindirilen tüm
/// canlı animasyon katmanları (yüzen ada, sürüklenen bulutlar, yağmur, güneş
/// ışınları, parıltılar, kuşlar, kelebekler, gökkuşağı parıltısı).
///
/// Her şey tek bir monotonik saatten ([clock], saniye cinsinden) beslenir;
/// böylece tüm katmanlar kadrajda senkron akar ve yalnızca bu dinleyici
/// değiştiğinde yeniden boyanır.
final class MochiScene extends StatefulWidget {
  const MochiScene({
    required this.stage,
    required this.clock,
    this.placements = const <MochiPlacement>[],
    super.key,
  });

  final MochiWorldStage stage;
  final ValueListenable<double> clock;

  /// Adada görünen elementler ([mochiCompose] sonucu). Listeye giren
  /// zıplayarak belirir, çıkan küçülerek kaybolur; kalanlar büyür ya da
  /// türünü (ör. solgun hâline) değiştirir.
  final List<MochiPlacement> placements;

  @override
  State<MochiScene> createState() => _MochiSceneState();
}

class _MochiSceneState extends State<MochiScene> {
  late List<_Cloud> _cloudsFar;
  late List<_Cloud> _cloudsNear;
  late List<_Drop> _drops;
  late List<_Mote> _motes;
  late List<_Bird> _birds;
  late List<_Butterfly> _butterflies;

  /// Her elementin son bilinen yerleşimi: listeden çıkan element bu yerde
  /// küçülerek kaybolabilsin.
  final Map<String, MochiPlacement> _last = {};

  @override
  void initState() {
    super.initState();
    _buildParticles();
    _remember();
  }

  @override
  void didUpdateWidget(covariant MochiScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ada büyüdükçe (parıltı, kuş, kelebek) parçacık alanını yenile.
    if (oldWidget.stage != widget.stage) _buildParticles();
    _remember();
  }

  void _remember() {
    for (final p in widget.placements) {
      _last[p.key] = p;
    }
  }

  /// Çizim listesi: görünenler (zemin dokusu önce, arkadan öne) ve
  /// kaybolmakta olanlar, son yerlerinde.
  List<({MochiPlacement placement, bool shown, int order})> _drawList() {
    final shownKeys = {for (final p in widget.placements) p.key};
    final items = [
      for (final (i, p) in widget.placements.indexed)
        (placement: p, shown: true, order: i),
      for (final p in _last.values)
        if (!shownKeys.contains(p.key)) (placement: p, shown: false, order: 0),
    ];
    items.sort((a, b) {
      final pa = a.placement;
      final pb = b.placement;
      if (pa.decal != pb.decal) return pa.decal ? -1 : 1;
      return pa.y.compareTo(pb.y);
    });
    return items;
  }

  void _buildParticles() {
    // Sabit tohumlar; her tür kendi dizisinden beslenir ki birinin sayısı
    // ya da taban görseli değişince diğerleri yerinden oynamasın.
    const seed = 0x5EED;
    math.Random rnd(int salt) => math.Random(seed ^ salt);
    final s = widget.stage;

    final clouds = rnd(1);
    _cloudsFar = _makeClouds(clouds, count: 5, near: false);
    _cloudsNear = _makeClouds(clouds, count: 4, near: true);

    final isWet = s.weather != MochiWeather.sunny;
    final dropCount = s.weather == MochiWeather.storm ? 150 : (isWet ? 90 : 0);
    final drops = rnd(2);
    _drops = List.generate(dropCount, (_) => _Drop.random(drops));

    final moteCount = (s.lushness * 34).round();
    final motes = rnd(3);
    _motes = List.generate(moteCount, (_) => _Mote.random(motes));

    final birds = rnd(4);
    _birds = s.birds
        ? List.generate(3, (i) => _Bird.random(birds, i))
        : const <_Bird>[];
    final butterflies = rnd(5);
    _butterflies = s.butterflies
        ? List.generate(5, (_) => _Butterfly.random(butterflies))
        : const <_Butterfly>[];
  }

  List<_Cloud> _makeClouds(
    math.Random rnd, {
    required int count,
    required bool near,
  }) {
    return List.generate(count, (i) {
      // Bulutlar sağa/sola karışık sürüklensin ("sağa sola gitme" hissi).
      final dir = rnd.nextBool() ? 1.0 : -1.0;
      final baseSpeed = near ? 0.012 : 0.006;
      // Yalnızca adanın üstündeki ve altındaki gökyüzünde gezinsinler;
      // adanın önüne geçip elementleri sisli göstermesinler.
      final below = near && i.isOdd;
      final fy = below
          ? 0.78 + rnd.nextDouble() * 0.17
          : 0.01 + rnd.nextDouble() * (near ? 0.12 : 0.11);
      return _Cloud(
        fx: rnd.nextDouble(),
        fy: fy,
        scale: (near ? 0.16 : 0.10) + rnd.nextDouble() * (near ? 0.12 : 0.08),
        speed: dir * (baseSpeed + rnd.nextDouble() * baseSpeed),
        opacity: (near ? 0.42 : 0.26) + rnd.nextDouble() * 0.18,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stage;
    final clock = widget.clock;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // 0) Gökyüzü zemini — ada tam genişlikte gösterilince üstte/altta
          //    kalan boşluğu havaya uygun temiz bir gradyanla doldurur.
          _SkyBackground(weather: s.weather),

          // 1) Yüzen ada — tam genişlik, üst/alt taşma yok; ada optik merkezde.
          Positioned.fill(
            child: _FloatingImage(
              asset: s.asset,
              clock: clock,
              lushness: s.lushness,
              elements: _drawList(),
            ),
          ),

          // 2) Uzak bulutlar (yavaş, soluk).
          CustomPaint(
            painter: _CloudsPainter(clock: clock, clouds: _cloudsFar),
          ),

          // 3) Güneşli sahnelerde yumuşak ışık huzmeleri + sıcak parıltı.
          if (s.weather == MochiWeather.sunny)
            CustomPaint(
              painter: _SunRaysPainter(clock: clock, lushness: s.lushness),
            ),

          // 4) Yakın bulutlar (daha hızlı, daha belirgin — paralaks derinlik).
          CustomPaint(
            painter: _CloudsPainter(clock: clock, clouds: _cloudsNear),
          ),

          // 5) Yağmur / fırtına.
          if (_drops.isNotEmpty)
            CustomPaint(
              painter: _RainPainter(
                clock: clock,
                drops: _drops,
                storm: s.weather == MochiWeather.storm,
              ),
            ),

          // 6) Havada süzülen parıltı tozları (yeşillik arttıkça yoğunlaşır).
          if (_motes.isNotEmpty)
            CustomPaint(
              painter: _MotesPainter(clock: clock, motes: _motes),
            ),

          // 7) Kelebekler.
          if (_butterflies.isNotEmpty)
            CustomPaint(
              painter: _ButterflyPainter(clock: clock, items: _butterflies),
            ),

          // 8) Kuşlar.
          if (_birds.isNotEmpty)
            CustomPaint(
              painter: _BirdPainter(clock: clock, birds: _birds),
            ),

          // 9) Gökkuşağı parıltısı (cennet sahnesi).
          if (s.rainbow)
            CustomPaint(painter: _RainbowShimmerPainter(clock: clock)),

          // 10) Hava durumuna göre ruh hâli örtüsü + fırtına şimşeği.
          IgnorePointer(
            child: _MoodOverlay(stage: s, clock: clock),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Yüzen ada ─────────────────────────────

/// mochi-world-*.png (941×1672) yükseklik / genişlik oranı.
const _kIslandAssetAspect = 1672 / 941;

/// Adanın (çimen üstü → kaya ucu) dikey merkezi, görsel yüksekliğine oranla.
const _kIslandCenter = 0.615;

/// Kaya ucunun altında kalan saf bulut/gökyüzü şeridi (≈ satır 1415 → 1672).
const _kCleanBottom = (1672 - 1415) / 1672;

/// Ada tam genişlikte (sağı/solu kırpılmadan) ve ekranın dikey ortasında
/// çizilir. Üstte/altta kalan alan, görselin kendi gökyüzü aynalanarak
/// doldurulur: dikiş satırı birebir aynı piksel olduğundan iz kalmaz ve
/// ekranın tamamı bulutlu gökyüzü olur.
final class _FloatingImage extends StatelessWidget {
  const _FloatingImage({
    required this.asset,
    required this.clock,
    required this.lushness,
    required this.elements,
  });

  final String asset;
  final ValueListenable<double> clock;
  final double lushness;
  final List<({MochiPlacement placement, bool shown, int order})> elements;

  /// Seviye değişiminde elementlerin büyüme/yer değiştirme süresi.
  static const _morph = Duration(milliseconds: 900);

  @override
  Widget build(BuildContext context) {
    // Daha gür ada daha canlı süzülür.
    final amp = 5.0 + lushness * 7.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        final h = w * _kIslandAssetAspect;
        // Görsel pikselinden ekran noktasına çarpan (941 px genişlik).
        final scale = w / 941;

        // Ada merkezini ekran merkezine oturt.
        final top = screenH / 2 - _kIslandCenter * h;

        // Alttaki boşluğu (süzülme payı dahil) yalnızca temiz bulut şeridi
        // görünecek kadar esneterek kapat.
        final bottomGap = screenH - (top + h) + amp + 8;
        final stretch = math.max(1.0, bottomGap / (_kCleanBottom * h));

        final image = Image.asset(
          asset,
          fit: BoxFit.fill,
          gaplessPlayback: true,
        );

        // Taban: üst gökyüzü aynası + alt bulut aynası + ada. Sağlık
        // değişince (yeşil ↔ kuru ↔ çatlak) yumuşakça birbirine geçer.
        final base = SizedBox(
          key: ValueKey(asset),
          width: w,
          height: screenH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                width: w,
                top: top - h,
                height: h,
                child: Transform.flip(flipY: true, child: image),
              ),
              Positioned(
                left: 0,
                width: w,
                top: top + h,
                height: h * stretch,
                child: Transform.flip(flipY: true, child: image),
              ),
              Positioned(left: 0, width: w, top: top, height: h, child: image),
            ],
          ),
        );

        return ClipRect(
          child: AnimatedBuilder(
            animation: clock,
            builder: (context, child) {
              // Yalnızca dikey süzülme: yatay kayma/dönme yanları açardı.
              final dy = math.sin(clock.value * 0.9) * amp;
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1200),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: base,
                  ),
                ),
                // Ada üstündeki elementler (görsel pikseli → ekran).
                for (final (:placement, :shown, :order) in elements)
                  AnimatedPositioned(
                    key: ValueKey(placement.key),
                    duration: _morph,
                    curve: Curves.easeInOutCubic,
                    left: (placement.x - placement.width / 2) * scale,
                    width: placement.width * scale,
                    bottom: screenH - (top + placement.y * scale),
                    child: MochiIslandElement(
                      placement: placement,
                      shown: shown,
                      clock: clock,
                      // Aynı anda gelenler sırayla zıplasın.
                      delay: Duration(milliseconds: math.min(order * 55, 700)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Havaya göre dikey gökyüzü gradyanı — görselin kenarlarındaki boşlukları
/// (ada tam genişlikte gösterildiğinde) doğal biçimde doldurur.
final class _SkyBackground extends StatelessWidget {
  const _SkyBackground({required this.weather});

  final MochiWeather weather;

  @override
  Widget build(BuildContext context) {
    final colors = switch (weather) {
      MochiWeather.sunny => const [
        Color(0xFFB8D9F0),
        Color(0xFFC5E0F2),
        Color(0xFFB8D9F0),
      ],
      MochiWeather.rainy => const [
        Color(0xFFBAC4CE),
        Color(0xFFCAD1D8),
        Color(0xFFD3D7DB),
      ],
      MochiWeather.storm => const [
        Color(0xFFA7B0BA),
        Color(0xFFBFC6CD),
        Color(0xFFCBCFD3),
      ],
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

// ───────────────────────────── Bulutlar ─────────────────────────────

final class _Cloud {
  _Cloud({
    required this.fx,
    required this.fy,
    required this.scale,
    required this.speed,
    required this.opacity,
  });

  final double fx;
  final double fy;
  final double scale;
  final double speed;
  final double opacity;
}

final class _CloudsPainter extends CustomPainter {
  _CloudsPainter({required this.clock, required this.clouds})
    : super(repaint: clock);

  final ValueListenable<double> clock;
  final List<_Cloud> clouds;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    for (final c in clouds) {
      // Sarmalı akış: ekranın solundan çıkıp sağdan geri girsin.
      var fx = (c.fx + c.speed * t) % 1.4;
      if (fx < 0) fx += 1.4;
      final cx = (fx - 0.2) * size.width;
      final cy = c.fy * size.height;
      final r = c.scale * size.width;
      _drawCloud(canvas, Offset(cx, cy), r, c.opacity);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double r, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.22);
    // Üst üste binmiş kabarcıklardan klasik bulut silüeti.
    canvas.drawCircle(center + Offset(-r * 0.6, r * 0.12), r * 0.5, paint);
    canvas.drawCircle(center + Offset(r * 0.6, r * 0.14), r * 0.46, paint);
    canvas.drawCircle(center + Offset(-r * 0.1, -r * 0.18), r * 0.58, paint);
    canvas.drawCircle(center + Offset(r * 0.28, r * 0.02), r * 0.5, paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, r * 0.28),
        width: r * 2.1,
        height: r * 0.7,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter old) => false;
}

// ───────────────────────────── Yağmur ─────────────────────────────

final class _Drop {
  _Drop({
    required this.fx,
    required this.fy,
    required this.len,
    required this.speed,
    required this.thick,
    required this.opacity,
  });

  factory _Drop.random(math.Random r) => _Drop(
    fx: r.nextDouble(),
    fy: r.nextDouble(),
    len: 0.03 + r.nextDouble() * 0.05,
    speed: 0.9 + r.nextDouble() * 0.8,
    thick: 0.8 + r.nextDouble() * 1.4,
    opacity: 0.18 + r.nextDouble() * 0.28,
  );

  final double fx;
  final double fy;
  final double len;
  final double speed;
  final double thick;
  final double opacity;
}

final class _RainPainter extends CustomPainter {
  _RainPainter({required this.clock, required this.drops, required this.storm})
    : super(repaint: clock);

  final ValueListenable<double> clock;
  final List<_Drop> drops;
  final bool storm;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final windDx = storm ? size.width * 0.05 : size.width * 0.025;
    final speedMul = storm ? 1.5 : 1.0;
    final tint = storm ? const Color(0xFFDCE6F0) : const Color(0xFFEAF2FA);
    for (final d in drops) {
      var fy = (d.fy + d.speed * speedMul * t) % 1.12;
      if (fy < 0) fy += 1.12;
      final x = d.fx * size.width;
      final y = fy * size.height - size.height * 0.1;
      final len = d.len * size.height * (storm ? 1.3 : 1.0);
      final paint = Paint()
        ..color = tint.withValues(alpha: d.opacity)
        ..strokeWidth = d.thick
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + windDx * d.len * 10, y + len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => false;
}

// ───────────────────────── Parıltı tozları ─────────────────────────

final class _Mote {
  _Mote({
    required this.fx,
    required this.fy,
    required this.size,
    required this.speed,
    required this.phase,
    required this.warm,
  });

  factory _Mote.random(math.Random r) => _Mote(
    fx: r.nextDouble(),
    fy: r.nextDouble(),
    size: 1.0 + r.nextDouble() * 2.4,
    speed: 0.01 + r.nextDouble() * 0.03,
    phase: r.nextDouble() * math.pi * 2,
    warm: r.nextBool(),
  );

  final double fx;
  final double fy;
  final double size;
  final double speed;
  final double phase;
  final bool warm;
}

final class _MotesPainter extends CustomPainter {
  _MotesPainter({required this.clock, required this.motes})
    : super(repaint: clock);

  final ValueListenable<double> clock;
  final List<_Mote> motes;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    for (final m in motes) {
      // Yukarı doğru süzülür, yatayda hafif salınır.
      var fy = (m.fy - m.speed * t) % 1.1;
      if (fy < 0) fy += 1.1;
      final sway = math.sin(t * 0.8 + m.phase) * 0.02;
      final x = ((m.fx + sway) % 1.0) * size.width;
      final y = fy * size.height;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2.2 + m.phase));
      final color = (m.warm ? const Color(0xFFFFF4C8) : Colors.white)
          .withValues(alpha: 0.5 * twinkle);
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(x, y), m.size * (0.7 + 0.3 * twinkle), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MotesPainter old) => false;
}

// ───────────────────────── Güneş ışınları ─────────────────────────

final class _SunRaysPainter extends CustomPainter {
  _SunRaysPainter({required this.clock, required this.lushness})
    : super(repaint: clock);

  final ValueListenable<double> clock;
  final double lushness;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final sun = Offset(size.width * 0.22, -size.height * 0.04);

    // Sıcak çevresel parıltı.
    final glowR = size.width * 0.9;
    final glow = Paint()
      ..shader = ui.Gradient.radial(sun, glowR, [
        const Color(0x33FFF3C0),
        const Color(0x00FFF3C0),
      ]);
    canvas.drawCircle(sun, glowR, glow);

    // Dönen yumuşak huzmeler.
    const rays = 9;
    final baseAngle = t * 0.04;
    final beam = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.03);
    final len = size.height * 1.15;
    for (var i = 0; i < rays; i++) {
      final a = baseAngle + i * (math.pi / rays) * 1.0;
      final flick = 0.5 + 0.5 * math.sin(t * 0.7 + i);
      final width = size.width * (0.012 + 0.01 * flick);
      final dir = Offset(math.cos(a), math.sin(a).abs() + 0.2);
      final p1 = sun + dir * len;
      final perp = Offset(-dir.dy, dir.dx);
      final path = Path()
        ..moveTo(sun.dx - perp.dx * width, sun.dy - perp.dy * width)
        ..lineTo(sun.dx + perp.dx * width, sun.dy + perp.dy * width)
        ..lineTo(p1.dx + perp.dx * width * 3, p1.dy + perp.dy * width * 3)
        ..lineTo(p1.dx - perp.dx * width * 3, p1.dy - perp.dy * width * 3)
        ..close();
      beam.color = Color.fromRGBO(255, 244, 200, 0.05 + 0.05 * flick);
      canvas.drawPath(path, beam);
    }
  }

  @override
  bool shouldRepaint(covariant _SunRaysPainter old) => false;
}

// ───────────────────────────── Kuşlar ─────────────────────────────

final class _Bird {
  _Bird({
    required this.fy,
    required this.speed,
    required this.scale,
    required this.phase,
  });

  factory _Bird.random(math.Random r, int i) => _Bird(
    fy: 0.12 + r.nextDouble() * 0.25,
    speed: 0.05 + r.nextDouble() * 0.04,
    scale: 0.6 + r.nextDouble() * 0.6,
    phase: i * 0.35 + r.nextDouble() * 0.3,
  );

  final double fy;
  final double speed;
  final double scale;
  final double phase;
}

final class _BirdPainter extends CustomPainter {
  _BirdPainter({required this.clock, required this.birds})
    : super(repaint: clock);

  final ValueListenable<double> clock;
  final List<_Bird> birds;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final paint = Paint()
      ..color = const Color(0x99586070)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final b in birds) {
      var fx = (b.phase + b.speed * t) % 1.3;
      if (fx < 0) fx += 1.3;
      final x = (fx - 0.15) * size.width;
      final y = (b.fy + 0.015 * math.sin(t * 1.5 + b.phase)) * size.height;
      final w = 14.0 * b.scale;
      // Kanat çırpışı: kol eğrisi yukarı/aşağı salınır.
      final flap = math.sin(t * 7 + b.phase);
      final lift = w * 0.5 * flap;
      final path = Path()
        ..moveTo(x - w, y + w * 0.1)
        ..quadraticBezierTo(x - w * 0.4, y - lift, x, y)
        ..quadraticBezierTo(x + w * 0.4, y - lift, x + w, y + w * 0.1);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BirdPainter old) => false;
}

// ───────────────────────────── Kelebekler ─────────────────────────────

final class _Butterfly {
  _Butterfly({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.speed,
    required this.phase,
    required this.size,
    required this.color,
  });

  factory _Butterfly.random(math.Random r) {
    const palette = [
      Color(0xFFFFC857),
      Color(0xFFFF8FB1),
      Color(0xFF8FD3FF),
      Color(0xFFC8A2FF),
      Color(0xFFFFFFFF),
    ];
    // Adanın çimenli üst yüzeyinin üstünde gezinsinler (ekranın ~%34–58'i).
    return _Butterfly(
      cx: 0.22 + r.nextDouble() * 0.56,
      cy: 0.38 + r.nextDouble() * 0.16,
      rx: 0.06 + r.nextDouble() * 0.10,
      ry: 0.025 + r.nextDouble() * 0.035,
      speed: 0.4 + r.nextDouble() * 0.5,
      phase: r.nextDouble() * math.pi * 2,
      size: 4.5 + r.nextDouble() * 2.5,
      color: palette[r.nextInt(palette.length)],
    );
  }

  final double cx;
  final double cy;
  final double rx;
  final double ry;
  final double speed;
  final double phase;
  final double size;
  final Color color;
}

final class _ButterflyPainter extends CustomPainter {
  _ButterflyPainter({required this.clock, required this.items})
    : super(repaint: clock);

  final ValueListenable<double> clock;
  final List<_Butterfly> items;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    for (final b in items) {
      // Lissajous gezinme: dağınık, doğal bir uçuş.
      final p = t * b.speed + b.phase;
      final x = (b.cx + b.rx * math.sin(p)) * size.width;
      final y = (b.cy + b.ry * math.sin(p * 2)) * size.height;
      // Kanat çırpışı: kanatlar gövdeden açılıp kapanır; tamamen kapanıp
      // çizgiye dönüşmesin diye alt sınır var.
      final flap = 0.45 + 0.55 * math.sin(t * 9 + b.phase).abs();
      final s = b.size;

      final body = Paint()..color = const Color(0xE63A2E2A);
      final upper = Paint()..color = b.color.withValues(alpha: 0.95);
      final lower = Paint()
        ..color = Color.lerp(
          b.color,
          const Color(0xFF3A2E2A),
          0.18,
        )!.withValues(alpha: 0.95);
      final antenna = Paint()
        ..color = const Color(0xB33A2E2A)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(0.25 * math.sin(p));
      for (final side in const [-1.0, 1.0]) {
        // Üst kanat: büyük, hafif yukarı eğik.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(side * s * 0.75 * flap, -s * 0.35),
            width: s * 1.5 * flap,
            height: s * 1.25,
          ),
          upper,
        );
        // Alt kanat: küçük, biraz koyu.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(side * s * 0.55 * flap, s * 0.45),
            width: s * 1.05 * flap,
            height: s * 0.9,
          ),
          lower,
        );
        // Anten.
        canvas.drawLine(
          Offset(side * s * 0.08, -s * 0.7),
          Offset(side * s * 0.4, -s * 1.25),
          antenna,
        );
      }
      // Gövde.
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * 0.28,
              height: s * 1.5,
            ),
            Radius.circular(s * 0.14),
          ),
          body,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ButterflyPainter old) => false;
}

// ─────────────────────── Gökkuşağı parıltısı ───────────────────────

final class _RainbowShimmerPainter extends CustomPainter {
  _RainbowShimmerPainter({required this.clock}) : super(repaint: clock);

  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    // Üst bölgede yavaşça süzülen yumuşak ışık süpürmesi.
    final sweep = (math.sin(t * 0.5) * 0.5 + 0.5);
    final cx = size.width * (0.2 + sweep * 0.6);
    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(
        Offset(cx, size.height * 0.22),
        size.width * 0.32,
        [const Color(0x30FFFFFF), const Color(0x00FFFFFF)],
      );
    canvas.drawCircle(Offset(cx, size.height * 0.22), size.width * 0.32, glow);

    // Pırıl pırıl küçük yıldızlar.
    for (var i = 0; i < 14; i++) {
      final a = i * 2.3999632; // altın açı — düzgün dağılım
      final rr = (i / 14) * size.width * 0.42;
      final bx = size.width * 0.5 + math.cos(a) * rr;
      final by = size.height * 0.2 + math.sin(a) * rr * 0.5;
      final tw = 0.5 + 0.5 * math.sin(t * 3 + i);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6 * tw)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      _drawSparkle(canvas, Offset(bx, by), 2 + 3 * tw, paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RainbowShimmerPainter old) => false;
}

// ─────────────────────── Ruh hâli örtüsü ───────────────────────

final class _MoodOverlay extends StatelessWidget {
  const _MoodOverlay({required this.stage, required this.clock});

  final MochiWorldStage stage;
  final ValueListenable<double> clock;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (stage.weather) {
      MochiWeather.storm => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55424A57), Color(0x00424A57), Color(0x33333A44)],
        stops: [0, 0.5, 1],
      ),
      MochiWeather.rainy => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x3368788C), Color(0x00000000)],
      ),
      MochiWeather.sunny => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x1AFFF0C0), Color(0x00000000), Color(0x14FFD9A0)],
        stops: [0, 0.55, 1],
      ),
    };

    final overlay = DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: const SizedBox.expand(),
    );

    if (stage.weather != MochiWeather.storm) return overlay;

    // Fırtınada ara sıra şimşek çakması.
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final t = clock.value;
        final cycle = t % 6.5; // ~6.5 saniyede bir
        var flash = 0.0;
        if (cycle < 0.18) {
          // Çift çakış, hızlı sönüm.
          flash =
              (math.sin(cycle / 0.18 * math.pi * 2).abs()) *
              (1 - cycle / 0.18) *
              0.5;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            overlay,
            if (flash > 0.001)
              ColoredBox(color: Colors.white.withValues(alpha: flash)),
          ],
        );
      },
    );
  }
}
