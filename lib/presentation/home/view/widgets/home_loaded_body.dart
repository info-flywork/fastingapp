part of '../home_view.dart';

/// Home yüklendi durumu gövdesi.
///
/// [ListView.builder] ile yalnızca görünür (ve cache) widget'lar build edilir.
final class HomeLoadedBody extends StatelessWidget {
  const HomeLoadedBody({
    required this.user,
    required this.progress,
    required this.isPremium,
    required this.summary,
    required this.onPremiumTapped,
    required this.onChatTapped,
    required this.onWaterTapped,
    required this.onStepsTapped,
    required this.onWeightTapped,
    required this.onWeightEditTapped,
    required this.onMealRecordsTapped,
    required this.onHungerTrackerTapped,
    super.key,
  });

  final User user;
  final UserProgress progress;
  final bool isPremium;
  final HomeSummary? summary;
  final VoidCallback onPremiumTapped;
  final VoidCallback onChatTapped;
  final VoidCallback onWaterTapped;
  final VoidCallback onStepsTapped;
  final VoidCallback onWeightTapped;
  final VoidCallback onWeightEditTapped;
  final VoidCallback onMealRecordsTapped;
  final VoidCallback onHungerTrackerTapped;

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems();
    return SafeArea(
      top: false,
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppBottomNav.barClearance),
        // Ekran dışındakiler tutulmasın; tekrar görünce yeniden build.
        addAutomaticKeepAlives: false,
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
      ),
    );
  }

  /// Aktif oruç / yeme penceresi yoksa oruç kartı gizlenir; diğerleri kalır.
  List<Widget> _visibleItems() {
    final week = summary?.week ?? const <SummaryWeekDay>[];
    final hasFast =
        summary?.activeFast != null || summary?.eatingWindow != null;

    return [
      HomeTopBar(
        streakDays: progress.streakDays,
        isPremium: isPremium,
        onPremiumTapped: onPremiumTapped,
        onChatTapped: onChatTapped,
      ),
      HomeWeekStrip(days: week),
      if (hasFast)
        HomeFastingCard(
          activeFast: summary?.activeFast,
          eatingWindow: summary?.eatingWindow,
          serverTime: summary?.serverTime,
        ),
      const HomeChallengeCard(),
      HomeMetricCards(
        waterMl: summary?.waterMl ?? 0,
        waterGoalMl: summary?.waterGoalMl ?? 2500,
        steps: summary?.steps ?? 0,
        stepsGoal: summary?.stepsGoal ?? 8000,
        onWaterTapped: onWaterTapped,
        onStepsTapped: onStepsTapped,
      ),
      HomeWeightCard(
        currentKg: summary?.weightCurrentKg,
        startKg: summary?.weightStartKg,
        goalKg: summary?.weightGoalKg,
        onTap: onWeightTapped,
        onEditTap: onWeightEditTapped,
      ),
      const HomeMetabolicCard(),
      HomeMealRecordsCard(
        lastMeal: summary?.lastMeal,
        onTap: onMealRecordsTapped,
      ),
      HomeHungerTrackerCard(
        physicalCount: summary?.hungerPhysical ?? 0,
        emotionalCount: summary?.hungerEmotional ?? 0,
        onTap: onHungerTrackerTapped,
      ),
    ];
  }
}
