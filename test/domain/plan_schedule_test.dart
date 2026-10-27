import 'package:fastingapp/domain/fasting/plan_catalog_repository.dart';
import 'package:fastingapp/domain/fasting/plan_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolvePlanSchedule', () {
    test('15-9 akşam yemeği: 08:00–17:00, 15 saat oruç', () {
      final schedule = resolvePlanSchedule(
        fallbackFastHours: 15,
        fallbackEatHours: 9,
        cardTiming: 'skipDinner',
        planCode: '15_9',
      );
      expect(schedule.startHour, 8);
      expect(schedule.startMinute, 0);
      expect(schedule.endHour, 17);
      expect(schedule.eatHours, 9);
      expect(schedule.fastHours, 15);
    });

    test('16-8 kahvaltı ve akşam kartları farklı pencere', () {
      final breakfast = resolvePlanSchedule(
        fallbackFastHours: 16,
        fallbackEatHours: 8,
        cardTiming: 'skipBreakfast',
      );
      final dinner = resolvePlanSchedule(
        fallbackFastHours: 16,
        fallbackEatHours: 8,
        cardTiming: 'skipDinner',
      );
      expect(breakfast.startHour, 12);
      expect(breakfast.endHour, 20);
      expect(dinner.startHour, 8);
      expect(dinner.endHour, 16);
      expect(breakfast.eatMinutes, 8 * 60);
      expect(dinner.eatMinutes, 8 * 60);
    });

    test('katalog süresi kart başlığının önüne geçer', () {
      final schedule = resolvePlanSchedule(
        fallbackFastHours: 16,
        fallbackEatHours: 8,
        cardTiming: 'skipDinner',
        catalog: const PlanCatalogEntry(
          code: '15_9',
          isPremium: false,
          requiresSafetyAck: false,
          fastHours: 15,
          eatHours: 9,
          defaultTiming: 'skip_breakfast',
          defaultEatStart: '12:00',
        ),
      );
      expect(schedule.eatHours, 9);
      expect(schedule.fastHours, 15);
      expect(schedule.startHour, 8);
      expect(schedule.endHour, 17);
    });

    test('varsayılan başlangıç yalnızca o zamanlamanın kartına yazılır', () {
      const catalog = PlanCatalogEntry(
        code: '16_8',
        isPremium: false,
        requiresSafetyAck: false,
        fastHours: 16,
        eatHours: 8,
        defaultTiming: 'skipBreakfast',
        defaultEatStart: '11:30',
      );
      final breakfast = resolvePlanSchedule(
        fallbackFastHours: 16,
        fallbackEatHours: 8,
        cardTiming: 'skipBreakfast',
        catalog: catalog,
      );
      final dinner = resolvePlanSchedule(
        fallbackFastHours: 16,
        fallbackEatHours: 8,
        cardTiming: 'skipDinner',
        catalog: catalog,
      );
      expect(breakfast.startHour, 11);
      expect(breakfast.startMinute, 30);
      expect(breakfast.endHour, 19);
      expect(breakfast.endMinute, 30);
      expect(dinner.startHour, 8);
      expect(dinner.endHour, 16);
    });

    test('örnek pencere süreyle uyuşuyorsa başlangıcı o olur', () {
      final schedule = resolvePlanSchedule(
        fallbackFastHours: 15,
        fallbackEatHours: 9,
        cardTiming: 'skipDinner',
        detail: const PlanCatalogDetail(
          code: '15_9',
          fastHours: 15,
          eatHours: 9,
          defaultTiming: 'skip_dinner',
          exampleStart: '08:30',
          exampleEnd: '17:30',
        ),
      );
      expect(schedule.startHour, 8);
      expect(schedule.startMinute, 30);
      expect(schedule.endHour, 17);
      expect(schedule.endMinute, 30);
    });

    test(
      'kayıtlı pencere aynı kartta ve süre uyuyorsa başlangıcı kaydırır',
      () {
        final dinner = resolvePlanSchedule(
          fallbackFastHours: 15,
          fallbackEatHours: 9,
          cardTiming: 'skipDinner',
          planCode: '15_9',
          currentPlanCode: '15_9',
          currentTiming: 'skipDinner',
          currentEatStart: '09:00',
          currentEatEnd: '18:00',
        );
        final breakfast = resolvePlanSchedule(
          fallbackFastHours: 15,
          fallbackEatHours: 9,
          cardTiming: 'skipBreakfast',
          planCode: '15_9',
          currentPlanCode: '15_9',
          currentTiming: 'skipDinner',
          currentEatStart: '09:00',
          currentEatEnd: '18:00',
        );
        expect(dinner.startHour, 9);
        expect(dinner.endHour, 18);
        expect(breakfast.startHour, 12);
        expect(breakfast.endHour, 21);
      },
    );
  });
}
