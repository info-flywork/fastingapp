import 'package:flutter/material.dart';

/// Seviye seçimi bottom sheet'i (örnek). (Doküman 9.5)
final class LevelSelectionBottomSheet extends StatelessWidget {
  const LevelSelectionBottomSheet({
    required this.currentLevel,
    required this.onLevelSelected,
    super.key,
  });

  final int? currentLevel;
  final ValueChanged<int?> onLevelSelected;

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text('Seviye seç'),
            // İskelet: seviye listesi buraya eklenir.
          ],
        ),
      ),
    );
  }
}
