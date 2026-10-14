import 'package:fastingapp/domain/fasting/plan_catalog_repository.dart';

/// `PUT /plans/current` bu planlarda `safetyAcknowledged: true` ister; yoksa
/// `SAFETY_ACK_REQUIRED`. Kaynak: plan kataloğu (`/catalog/plans`); katalog
/// yüklenemediyse yedek liste (backend `seeds/plans.json`).
const _safetyAckPlanCodes = <String>{
  '20_4',
  '21_3',
  '22_2',
  '23_1',
  'omad',
  '5_2',
  '6_1',
  'alternate_day',
};

bool planRequiresSafetyAck(String? planCode) =>
    PlanCatalogRepository.instance?.entry(planCode)?.requiresSafetyAck ??
    _safetyAckPlanCodes.contains(planCode);
