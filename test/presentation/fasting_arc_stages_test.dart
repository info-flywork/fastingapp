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
      expect(stages.where((s) => s.isReached).map((s) => s.index), [
        0,
        1,
        2,
        3,
      ]);
      expect(stages.singleWhere((s) => s.isCurrent).index, 3);
    });

    test('16:8 bittiğinde son aşama ketoz; 18s ve sonrası yok', () {
      final stages = bodyArcStages(
        targetHours: 16,
        elapsedHours: 16,
        active: true,
      );
      expect(stages.map((s) => s.index), [0, 1, 2, 3, 4, 5]);
      expect(stages.singleWhere((s) => s.isCurrent).index, 5);
      expect(bodyPlanStageIndex(targetHours: 16, elapsedHours: 40), 5);
    });

    test('12:12 ketozu içermez; bitince yağ yakımında kalır', () {
      expect(bodyPlanStageIndices(12), [0, 1, 2, 3, 4]);
      expect(bodyPlanStageIndex(targetHours: 12, elapsedHours: 12), 4);
    });

    test('20:4 — yakın işaretler seyreltilir, başlangıç kalır', () {
      final stages = bodyArcStages(
        targetHours: 20,
        elapsedHours: 0,
        active: true,
      );
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
      expect(eatingStageIndex(0, 480), 0);
      expect(eatingStageIndex(95, 480), 0);
      expect(eatingStageIndex(96, 480), 1);
      expect(eatingStageIndex(419, 480), 1);
      expect(eatingStageIndex(420, 480), 2);
      expect(eatingStageIndex(20, 60), 0);
    });
  });

  group('mealCycleArc', () {
    test('16:8 — öğün yayda %60; boz ondan önce', () {
      final arc = mealCycleArc(fastMinutes: 960, eatMinutes: 480);
      expect(arc.stages.map((s) => s.index), [1, 2, 3]);
      final breakT = arc.stages[0].t;
      final nourishT = arc.stages[1].t;
      expect(breakT, lessThan(0.5));
      expect(nourishT, closeTo(0.6, 1e-9));
      expect(breakT, lessThan(nourishT));
      expect(arc.stages.last.t, 1);
    });

    test('14:10 ile 18:6 — boz noktası plana göre kayar; öğün %60', () {
      final a = mealCycleArc(fastMinutes: 14 * 60, eatMinutes: 10 * 60);
      final b = mealCycleArc(fastMinutes: 18 * 60, eatMinutes: 6 * 60);
      expect(a.stages.first.t, lessThan(b.stages.first.t));
      expect(a.stages[1].t, closeTo(0.6, 1e-9));
      expect(b.stages[1].t, closeTo(0.6, 1e-9));
    });

    test('oruçta: ilerleme boz noktasına doğru ölçeklenir', () {
      final breakT = mealArcBreakT(960, 480);
      final arc = mealCycleArc(
        fastMinutes: 960,
        eatMinutes: 480,
        fastElapsedMinutes: 480, // yarı
      );
      expect(arc.progress, closeTo(breakT * 0.5, 1e-9));
      expect(arc.stages.any((s) => s.isReached), isFalse);
      final done = mealCycleArc(
        fastMinutes: 960,
        eatMinutes: 480,
        fastElapsedMinutes: 960,
      );
      expect(done.progress, closeTo(breakT, 1e-9));
    });

    test('yeme penceresinde: beslen aşaması mevcut', () {
      final arc = mealCycleArc(
        fastMinutes: 960,
        eatMinutes: 480,
        eatElapsedMinutes: 120,
      );
      expect(arc.stages.singleWhere((s) => s.isCurrent).index, 2);
      expect(arc.stages.where((s) => s.isReached).map((s) => s.index), [1, 2]);
      expect(arc.progress, greaterThan(mealArcBreakT(960, 480)));
    });

    test('kısa pencerede (OMAD) işaretler üst üste binmez', () {
      final arc = mealCycleArc(fastMinutes: 1380, eatMinutes: 60);
      final gap = mealArcMinGap(1380, 60);
      for (var i = 1; i < arc.stages.length; i++) {
        expect(
          arc.stages[i].t - arc.stages[i - 1].t,
          greaterThanOrEqualTo(gap - 1e-9),
        );
      }
      expect(arc.stages.map((s) => s.index), contains(1));
      final nourish = arc.stages.where((s) => s.index == 2);
      if (nourish.isNotEmpty) {
        expect(nourish.first.t, closeTo(0.6, 0.12));
      }
    });
  });
}
