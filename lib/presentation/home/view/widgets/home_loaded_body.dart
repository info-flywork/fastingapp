part of '../home_view.dart';

/// Home yüklendi durumu gövdesi. Alt bölümleri ayrı widget'lara delege eder.
final class HomeLoadedBody extends StatelessWidget {
  const HomeLoadedBody({
    required this.user,
    required this.progress,
    required this.isPremium,
    required this.onPremiumTapped,
    super.key,
  });

  final User user;
  final UserProgress progress;
  final bool isPremium;
  final VoidCallback onPremiumTapped;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          HomeHeaderSection(user: user),
          LevelProgressCard(progress: progress),
          if (!isPremium) PremiumCard(onTap: onPremiumTapped),
        ],
      ),
    );
  }
}
