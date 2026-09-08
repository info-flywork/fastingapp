part of '../home_view.dart';

/// İlerleme kartı (seviye / streak).
final class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({required this.progress, super.key});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Level ${progress.level} · ${progress.streakDays} gün',
        ),
      ),
    );
  }
}
