part of '../language_level_view.dart';

/// Tek bir seviye kartı.
final class LevelCard extends StatelessWidget {
  const LevelCard({
    required this.level,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final int level;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        selected: isSelected,
        onTap: onTap,
        title: Text('Level $level'),
        trailing: isSelected ? const Icon(Icons.check) : null,
      ),
    );
  }
}
