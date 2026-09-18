part of '../home_view.dart';

/// Home yüklendi durumu gövdesi.
///
/// [ListView.builder] ile yalnızca görünür (ve cache) widget'lar build edilir.
final class HomeLoadedBody extends StatelessWidget {
  const HomeLoadedBody({
    required this.user,
    required this.progress,
    required this.isPremium,
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
  final VoidCallback onPremiumTapped;
  final VoidCallback onChatTapped;
  final VoidCallback onWaterTapped;
  final VoidCallback onStepsTapped;
  final VoidCallback onWeightTapped;
  final VoidCallback onWeightEditTapped;
  final VoidCallback onMealRecordsTapped;
  final VoidCallback onHungerTrackerTapped;

  static const _itemCount = 9;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        // Ekran dışındakiler tutulmasın; tekrar görünce yeniden build.
        addAutomaticKeepAlives: false,
        itemCount: _itemCount,
        itemBuilder: (context, index) => _buildItem(index),
      ),
    );
  }

  Widget _buildItem(int index) {
    return switch (index) {
      0 => HomeTopBar(
        streakDays: progress.streakDays > 0 ? progress.streakDays : 3,
        isPremium: isPremium,
        onPremiumTapped: onPremiumTapped,
        onChatTapped: onChatTapped,
      ),
      1 => const HomeWeekStrip(),
      2 => const HomeFastingCard(),
      3 => const HomeChallengeCard(),
      4 => HomeMetricCards(
        onWaterTapped: onWaterTapped,
        onStepsTapped: onStepsTapped,
      ),
      5 => HomeWeightCard(onTap: onWeightTapped, onEditTap: onWeightEditTapped),
      6 => const HomeMetabolicCard(),
      7 => HomeMealRecordsCard(onTap: onMealRecordsTapped),
      8 => HomeHungerTrackerCard(onTap: onHungerTrackerTapped),
      _ => const SizedBox.shrink(),
    };
  }
}
