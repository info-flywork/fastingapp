import 'package:flutter/material.dart';

/// Mochi World'de gökyüzünün ruh hâli.
enum MochiWeather { sunny, rainy, storm }

/// Ada'nın tek bir "durumu" — kullanıcı verisine göre seçilen sahne.
///
/// Her sahne tam ekran bir arka plan görseli (bulutlu gökyüzü + uçan ada) ve
/// o görselin üstüne bindirilen animasyon katmanlarının ayarlarından oluşur.
@immutable
final class MochiWorldStage {
  const MochiWorldStage({
    required this.asset,
    required this.weather,
    required this.lushness,
    this.rainbow = false,
    this.birds = false,
    this.butterflies = false,
  });

  /// Tam ekran arka plan görseli.
  final String asset;

  /// Gökyüzünün havası — yağmur / fırtına katmanlarını açar.
  final MochiWeather weather;

  /// 0 (çorak) → 1 (cennet). Yüzen ivmeyi, parıltı yoğunluğunu ve
  /// adanın "nefes alma" genliğini ölçekler.
  final double lushness;

  /// Gökkuşağı parıltısı katmanı.
  final bool rainbow;

  /// Gökyüzünde süzülen kuşlar.
  final bool birds;

  /// Ada üzerinde uçuşan kelebekler.
  final bool butterflies;

  /// Çorak sahneler yağmurlu/kapalı, gür sahneler güneşli.
  bool get isDry => lushness < 0.25;
}

/// Kullanıcının ilerleyişine göre çorak → cennet sıralı sahne hattı.
///
/// Sıralama kasıtlı: ada önce canlanır (yağmur gelir), sonra yeşerir ve en
/// sonunda gökkuşaklı cennete dönüşür. Sürükleyici modda bu dizi otomatik
/// olarak baştan sona oynatılır.
const List<MochiWorldStage> kMochiWorldStages = <MochiWorldStage>[
  // 1 — Kurak, çatlamış toprak, gri gökyüzü.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-7.png',
    weather: MochiWeather.storm,
    lushness: 0.02,
  ),
  // 2 — Kurak, gün batımı sıcaklığı.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-6.png',
    weather: MochiWeather.sunny,
    lushness: 0.08,
  ),
  // 3 — Kurak ama güneşli, ilk filiz.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-5.png',
    weather: MochiWeather.sunny,
    lushness: 0.16,
  ),
  // 4 — Yağmur geliyor, toprak hâlâ çatlak.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-10.png',
    weather: MochiWeather.rainy,
    lushness: 0.30,
  ),
  // 5 — Yağmurda yeşeren ağaçlar, gölet.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-9.png',
    weather: MochiWeather.rainy,
    lushness: 0.45,
  ),
  // 6 — Fırtınada bile gür; şelale, dağ.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-8.png',
    weather: MochiWeather.storm,
    lushness: 0.58,
  ),
  // 7 — Güneşli, sağlıklı yeşil.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-1.png',
    weather: MochiWeather.sunny,
    lushness: 0.70,
  ),
  // 8 — Çiçeklenen patika, tepeler.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-2.png',
    weather: MochiWeather.sunny,
    lushness: 0.82,
  ),
  // 9 — Bereketli; kelebekler.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-3.png',
    weather: MochiWeather.sunny,
    lushness: 0.92,
    butterflies: true,
  ),
  // 10 — Gökkuşaklı cennet; kuşlar + kelebekler.
  MochiWorldStage(
    asset: 'assets/images/mochi-world-4.png',
    weather: MochiWeather.sunny,
    lushness: 1.0,
    rainbow: true,
    birds: true,
    butterflies: true,
  ),
];
