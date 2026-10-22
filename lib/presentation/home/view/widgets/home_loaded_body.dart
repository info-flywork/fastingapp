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

    return [
      HomeTopBar(
        streakDays: progress.streakDays,
        isPremium: isPremium,
        onPremiumTapped: onPremiumTapped,
        onChatTapped: onChatTapped,
      ),
      HomeWeekStrip(days: week),
      // Cubit (optimistic start) özetten önce dolabilir — ikisini birleştir.
      BlocBuilder<FastingSessionCubit, FastingSessionState>(
        bloc: getIt<FastingSessionCubit>(),
        buildWhen: (a, b) =>
            a.fast?.id != b.fast?.id ||
            a.eatingWindow?.endsAt != b.eatingWindow?.endsAt ||
            a.fetchedAt != b.fetchedAt,
        builder: (context, session) {
          final fast = session.fast ?? summary?.activeFast;
          final eating = fast != null
              ? null
              : (session.eatingWindow ?? summary?.eatingWindow);
          if (fast == null && eating == null) {
            return const SizedBox.shrink();
          }
          return HomeFastingCard(
            activeFast: fast,
            eatingWindow: eating,
            serverTime: session.fetchedAt != null
                ? DateTime.now().add(session.clockOffset)
                : summary?.serverTime,
          );
        },
      ),
      const HomeChallengeCard(),
      HomeMetricCards(
        waterMl: summary?.waterMl ?? 0,
        waterGoalMl: summary?.waterGoalMl ?? 2500,
        steps: summary?.steps ?? 0,
        stepsGoal: summary?.stepsGoal ?? 8000,
        waterUnit: summary?.waterUnit ?? 'ml',
        onWaterTapped: onWaterTapped,
        onStepsTapped: onStepsTapped,
      ),
      HomeWeightCard(
        currentKg: summary?.weightCurrentKg,
        startKg: summary?.weightStartKg,
        goalKg: summary?.weightGoalKg,
        unit: summary?.weightUnit ?? 'kg',
        onTap: onWeightTapped,
        onEditTap: onWeightEditTapped,
      ),
      // Metabolik kart: değerler sabit (backend faz 7); veri gelene kadar gizli.
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
