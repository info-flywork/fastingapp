part of '../home_view.dart';

/// Home yüklendi durumu gövdesi.
///
/// Kartlar bir kez kurulur ve kaydırırken yaşar. Önceden `ListView.builder`
/// ekrandan çıkanı atıyordu: geri kaydırınca ilerleme çubukları sıfırdan
/// dolma animasyonunu tekrar oynatıyor, kartlar yeniden kurulup zıplıyordu.
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
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppBottomNav.barClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items,
        ),
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
