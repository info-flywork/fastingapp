part of '../home_view.dart';

/// Home yüklendi durumu gövdesi.
final class HomeLoadedBody extends StatelessWidget {
  const HomeLoadedBody({
    required this.user,
    required this.progress,
    required this.isPremium,
    required this.onPremiumTapped,
    required this.onChatTapped,
    required this.onWaterTapped,
    super.key,
  });

  final User user;
  final UserProgress progress;
  final bool isPremium;
  final VoidCallback onPremiumTapped;
  final VoidCallback onChatTapped;
  final VoidCallback onWaterTapped;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        children: [
          HomeTopBar(
            streakDays: progress.streakDays > 0 ? progress.streakDays : 3,
            isPremium: isPremium,
            onPremiumTapped: onPremiumTapped,
            onChatTapped: onChatTapped,
          ),
          const HomeWeekStrip(),
          const HomeFastingCard(),
          const HomeChallengeCard(),
          HomeMetricCards(onWaterTapped: onWaterTapped),
        ],
      ),
    );
  }
}
