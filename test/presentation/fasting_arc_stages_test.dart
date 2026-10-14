import 'package:fastingapp/presentation/fasting/fasting_arc_stages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bodyStageIndex', () {
    test('başlangıcı geçen süreden küçük/eşit olan son aşama', () {
      expect(bodyStageIndex(0), 0);
      expect(bodyStageIndex(1.9), 0);
      expect(bodyStageIndex(2), 1);
      expect(bodyStageIndex(12.5), 4);
      expect(bodyStageIndex(16), 5);
      expect(bodyStageIndex(100), 8);
    });
  });

  group('bodyArcStages', () {
    test('16:8 — işaretler başlangıç saati / hedef konumunda', () {
      final stages = bodyArcStages(
        targetHours: 16,
        elapsedHours: 9,
        active: true,
      );
      expect(stages.map((s) => s.index), [0, 1, 2, 3, 4, 5]);
      expect(stages.map((s) => s.t), [0, 2 / 16, 5 / 16, 8 / 16, 12 / 16, 1]);
      // 9. saatte: 0–8 sa aşamaları geçildi, mevcut aşama 8 sa (index 3).
      expect(stages.where((s) => s.isReached).map((s) => s.index), [
        0,
        1,
        2,
        3,
      ]);
      expect(stages.singleWhere((s) => s.isCurrent).index, 3);
    });

    test('20:4 — yakın işaretler seyreltilir, başlangıç kalır', () {
      final stages = bodyArcStages(
        targetHours: 20,
        elapsedHours: 0,
        active: true,
      );
      // 16 (0.8) ve 18 (0.9) çok yakın: sonraki kalır.
      expect(stages.first.index, 0);
      expect(stages.map((s) => s.index), isNot(contains(5)));
      expect(stages.last.index, 6);
      for (var i = 1; i < stages.length; i++) {
        expect(stages[i].t - stages[i - 1].t, greaterThanOrEqualTo(0.11));
      }
    });

    test('oruç yokken hepsi gri, mevcut aşama yok', () {
      final stages = bodyArcStages(
        targetHours: 16,
        elapsedHours: 5,
        active: false,
      );
      expect(stages.any((s) => s.isReached || s.isCurrent), isFalse);
    });
  });

  group('eatingStageIndex', () {
    test('ilk %20 (en az 30 dk) boz, son 60 dk sonraki, arası beslen', () {
      // 8 saatlik pencere: boz < 96 dk, sonraki ≥ 420 dk.
      expect(eatingStageIndex(0, 480), 0);
      expect(eatingStageIndex(95, 480), 0);
      expect(eatingStageIndex(96, 480), 1);
      expect(eatingStageIndex(419, 480), 1);
      expect(eatingStageIndex(420, 480), 2);
      // Kısa pencere (OMAD 60 dk): en az 30 dk boz.
      expect(eatingStageIndex(20, 60), 0);
    });
  });

  group('mealCycleArc', () {
    test('16:8 — 16. saatte orucunu boz, kum saati yayın sonunda', () {
      final arc = mealCycleArc(fastMinutes: 960, eatMinutes: 480);
      // Başta işaret yok; kum saati yayın bittiği uçta.
      expect(arc.stages.map((s) => s.index), [1, 2, 3]);
      expect(arc.stages.first.t, 960 / 1440);
      expect(arc.stages.last.t, 1);
      expect(arc.progress, 0);
      expect(arc.stages.any((s) => s.isReached), isFalse);
    });

    test('oruçta: ilerleme orucunu boz noktasına doğru, işaretler gri', () {
      final arc = mealCycleArc(
        fastMinutes: 960,
        eatMinutes: 480,
        fastElapsedMinutes: 720,
      );
      expect(arc.progress, 720 / 1440);
      expect(arc.stages.any((s) => s.isReached), isFalse);
      // Hedef aşılınca orucunu boz noktasında durur.
      final over = mealCycleArc(
        fastMinutes: 960,
        eatMinutes: 480,
        fastElapsedMinutes: 1200,
      );
      expect(over.progress, 960 / 1440);
    });

    test('yeme penceresinde: beslen aşaması mevcut', () {
      final arc = mealCycleArc(
        fastMinutes: 960,
        eatMinutes: 480,
        eatElapsedMinutes: 120,
      );
      expect(arc.progress, (960 + 120) / 1440);
      expect(arc.stages.singleWhere((s) => s.isCurrent).index, 2);
      expect(arc.stages.where((s) => s.isReached).map((s) => s.index), [1, 2]);
    });

    test('kısa pencerede (OMAD) işaretler üst üste binmez', () {
      final arc = mealCycleArc(fastMinutes: 1380, eatMinutes: 60);
      for (var i = 1; i < arc.stages.length; i++) {
        expect(
          arc.stages[i].t - arc.stages[i - 1].t,
          greaterThanOrEqualTo(0.11 - 1e-9),
        );
      }
      // Orucunu boz her zaman var.
      expect(arc.stages.map((s) => s.index), contains(1));
    });
  });
}
