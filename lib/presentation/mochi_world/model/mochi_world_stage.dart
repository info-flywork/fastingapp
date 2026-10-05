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

  @override
  bool operator ==(Object other) =>
      other is MochiWorldStage &&
      other.asset == asset &&
      other.weather == weather &&
      other.lushness == lushness &&
      other.rainbow == rainbow &&
      other.birds == birds &&
      other.butterflies == butterflies;

  @override
  int get hashCode =>
      Object.hash(asset, weather, lushness, rainbow, birds, butterflies);
}
