import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/bloc/diet_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_reason/bloc/fasting_reason_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/obstacles/bloc/obstacles_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/weight_history/bloc/weight_history_bloc.dart';

/// Onboarding boyunca yaşayan cevaplar (backend doküman 13 §3). Adım BLoC'ları
/// ekran kapanınca kaybolduğu için her adım cevabını buraya yazar;
/// `POST /user/onboarding` gövdesi buradan üretilir.
final class OnboardingDraft {
  OnboardingGoal? goal;
  OnboardingGender? gender;
  double? weightKg;
  double? goalWeightKg;
  int? heightCm;
  int? age;
  OnboardingDiet? diet;
  Set<OnboardingFoodLove> foodLoves = {};
  Set<OnboardingFoodSkip> foodSkips = {};
  OnboardingWeightHistory? weightHistory;
  Set<OnboardingObstacle> obstacles = {};
  OnboardingFastingReason? fastingReason;
  OnboardingFastingPlan? plan;

  /// "HH:mm"
  String? mealWindowStart;
  String? mealWindowEnd;

  /// İstemci plan enum'u → katalog kodu (backend `seeds/plans.json`).
  static const planCodes = <OnboardingFastingPlan, String>{
    OnboardingFastingPlan.sixteenEight: '16_8',
    OnboardingFastingPlan.fourteenTen: '14_10',
    OnboardingFastingPlan.eighteenSix: '18_6',
    OnboardingFastingPlan.twentyFour: '20_4',
    OnboardingFastingPlan.omad: 'omad',
    OnboardingFastingPlan.fiveTwo: '5_2',
  };

  /// Eksik zorunlu alanlar (boşsa gönderilebilir).
  List<String> get missing => [
    if (goal == null) 'goal',
    if (gender == null) 'gender',
    if (weightKg == null) 'weightKg',
    if (goalWeightKg == null) 'goalWeightKg',
    if (heightCm == null) 'heightCm',
    if (age == null) 'age',
    if (diet == null) 'diet',
    if (foodLoves.isEmpty) 'foodLoves',
    if (weightHistory == null) 'weightHistory',
    if (fastingReason == null) 'fastingReason',
    if (plan == null) 'plan',
    if (mealWindowStart == null || mealWindowEnd == null) 'mealWindow',
  ];

  /// `POST /user/onboarding` gövdesi. [termsVersion]/[privacyVersion]:
  /// `GET /app/config` → `legal`.
  Map<String, dynamic> toRequest({
    required String termsVersion,
    required String privacyVersion,
  }) => {
    'schemaVersion': 1,
    'goal': goal!.name,
    'gender': gender!.name,
    'weightKg': weightKg,
    'goalWeightKg': goalWeightKg,
    'heightCm': heightCm,
    'age': age,
    'diet': diet!.name,
    'foodLoves': foodLoves.map((e) => e.name).toList(),
    'foodSkips': foodSkips.map((e) => e.name).toList(),
    'weightHistory': weightHistory!.name,
    'obstacles': obstacles.map((e) => e.name).toList(),
    'fastingReason': fastingReason!.name,
    'planCode': planCodes[plan]!,
    'mealWindow': {'start': mealWindowStart, 'end': mealWindowEnd},
    // Gizlilik ekranı (privacyHighlight) ve giriş ekranındaki şartlar metni.
    // TODO(team): sağlık verisi ve AI işleme için ayrı açık rıza ekranı.
    'consents': {
      'terms': termsVersion,
      'privacy': privacyVersion,
      'healthData': true,
      'aiProcessing': true,
    },
  };

  void reset() {
    goal = null;
    gender = null;
    weightKg = null;
    goalWeightKg = null;
    heightCm = null;
    age = null;
    diet = null;
    foodLoves = {};
    foodSkips = {};
    weightHistory = null;
    obstacles = {};
    fastingReason = null;
    plan = null;
    mealWindowStart = null;
    mealWindowEnd = null;
  }
}
