import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fastingapp/presentation/mochi_world/model/mochi_world_stage.dart';
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
  const MochiScene({required this.stage, required this.clock, super.key});

  final MochiWorldStage stage;
  final ValueListenable<double> clock;

  @override
  State<MochiScene> createState() => _MochiSceneState();
}

class _MochiSceneState extends State<MochiScene> {
  late final List<_Cloud> _cloudsFar;
  late final List<_Cloud> _cloudsNear;
  late final List<_Drop> _drops;
  late final List<_Mote> _motes;
  late final List<_Bird> _birds;
  late final List<_Butterfly> _butterflies;

  @override
  void initState() {
    super.initState();
    // Görsele göre sabit bir tohum: sahne boyunca parçacık alanı sabit kalsın.
    final seed = widget.stage.asset.hashCode;
    final rnd = math.Random(seed);
    final s = widget.stage;

    _cloudsFar = _makeClouds(rnd, count: 5, near: false);
    _cloudsNear = _makeClouds(rnd, count: 4, near: true);

    final isWet = s.weather != MochiWeather.sunny;
    final dropCount = s.weather == MochiWeather.storm
        ? 150
        : (isWet ? 90 : 0);
    _drops = List.generate(dropCount, (_) => _Drop.random(rnd));

    final moteCount = (s.lushness * 34).round();
    _motes = List.generate(moteCount, (_) => _Mote.random(rnd));

    _birds = s.birds
        ? List.generate(3, (i) => _Bird.random(rnd, i))
        : const <_Bird>[];
    _butterflies = s.butterflies
        ? List.generate(5, (_) => _Butterfly.random(rnd))
        : const <_Butterfly>[];
  }

  List<_Cloud> _makeClouds(math.Random rnd, {required int count, required bool near}) {
    return List.generate(count, (_) {
      // Bulutlar sağa/sola karışık sürüklensin ("sağa sola gitme" hissi).
      final dir = rnd.nextBool() ? 1.0 : -1.0;
      final baseSpeed = near ? 0.012 : 0.006;
      return _Cloud(
        fx: rnd.nextDouble(),
        fy: (near ? 0.04 : 0.02) + rnd.nextDouble() * (near ? 0.34 : 0.30),
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
            ),
          ),

          // 2) Uzak bulutlar (yavaş, soluk).
          CustomPaint(painter: _CloudsPainter(clock: clock, clouds: _cloudsFar)),

          // 3) Güneşli sahnelerde yumuşak ışık huzmeleri + sıcak parıltı.
          if (s.weather == MochiWeather.sunny)
            CustomPaint(
              painter: _SunRaysPainter(clock: clock, lushness: s.lushness),
            ),

          // 4) Yakın bulutlar (daha hızlı, daha belirgin — paralaks derinlik).
          CustomPaint(painter: _CloudsPainter(clock: clock, clouds: _cloudsNear)),

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
            CustomPaint(painter: _MotesPainter(clock: clock, motes: _motes)),

          // 7) Kelebekler.
          if (_butterflies.isNotEmpty)
            CustomPaint(
              painter: _ButterflyPainter(clock: clock, items: _butterflies),
            ),

          // 8) Kuşlar.
          if (_birds.isNotEmpty)
            CustomPaint(painter: _BirdPainter(clock: clock, birds: _birds)),

          // 9) Gökkuşağı parıltısı (cennet sahnesi).
          if (s.rainbow)
            CustomPaint(painter: _RainbowShimmerPainter(clock: clock)),

          // 10) Hava durumuna göre ruh hâli örtüsü + fırtına şimşeği.
          IgnorePointer(child: _MoodOverlay(stage: s, clock: clock)),
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
  });

  final String asset;
  final ValueListenable<double> clock;
  final double lushness;

  @override
  Widget build(BuildContext context) {
    // Daha gür ada daha canlı süzülür.
    final amp = 5.0 + lushness * 7.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        final h = w * _kIslandAssetAspect;

        // Ada merkezini ekran merkezine oturt.
        final top = screenH / 2 - _kIslandCenter * h;

        // Alttaki boşluğu (süzülme payı dahil) yalnızca temiz bulut şeridi
        // görünecek kadar esneterek kapat.
        final bottomGap = screenH - (top + h) + amp + 8;
        final stretch = math.max(1.0, bottomGap / (_kCleanBottom * h));

        final image = Image.asset(asset, fit: BoxFit.fill);

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
                // Üst gökyüzü — görselin üst kenarının aynası.
                Positioned(
                  left: 0,
                  width: w,
                  top: top - h,
                  height: h,
                  child: Transform.flip(flipY: true, child: image),
                ),
                // Alt bulutlar — alt kenarın aynası, hafifçe esnetilmiş.
                Positioned(
                  left: 0,
                  width: w,
                  top: top + h,
                  height: h * stretch,
                  child: Transform.flip(flipY: true, child: image),
                ),
                // Ada.
                Positioned(
                  left: 0,
                  width: w,
                  top: top,
                  height: h,
                  child: image,
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
    final tint = storm
        ? const Color(0xFFDCE6F0)
        : const Color(0xFFEAF2FA);
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
    return _Butterfly(
      cx: 0.2 + r.nextDouble() * 0.6,
      cy: 0.45 + r.nextDouble() * 0.35,
      rx: 0.08 + r.nextDouble() * 0.14,
      ry: 0.05 + r.nextDouble() * 0.10,
      speed: 0.4 + r.nextDouble() * 0.5,
      phase: r.nextDouble() * math.pi * 2,
      size: 5.0 + r.nextDouble() * 4.0,
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
      // Kanat çırpışı: yatay ölçek açılıp kapanır.
      final flap = (0.25 + 0.75 * math.sin(t * 9 + b.phase).abs());
      final s = b.size;

      final body = Paint()..color = const Color(0xCC3A2E2A);
      final wing = Paint()..color = b.color.withValues(alpha: 0.92);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(0.3 * math.sin(p));
      // Sol kanat
      canvas.save();
      canvas.scale(flap, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-s * 0.7, 0), width: s * 1.3, height: s * 1.7),
        wing,
      );
      canvas.restore();
      // Sağ kanat
      canvas.save();
      canvas.scale(flap, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(s * 0.7, 0), width: s * 1.3, height: s * 1.7),
        wing,
      );
      canvas.restore();
      // Gövde
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s * 0.35, height: s * 1.6),
          Radius.circular(s * 0.2),
        ),
        body,
      );
      canvas.restore();
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
          flash = (math.sin(cycle / 0.18 * math.pi * 2).abs()) *
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
