import 'package:fastingapp/core/bottom_sheets/bottom_sheet_handler.dart';
import 'package:fastingapp/core/bottom_sheets/widgets/level_selection_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// Tüm bottom sheet'lerin tek giriş noktası (singleton). (Doküman 9.5)
final class AppBottomSheets extends BottomSheetHandler {
  AppBottomSheets._init();

  static final AppBottomSheets _instance = AppBottomSheets._init();

  static AppBottomSheets get instance => _instance;

  Future<void> showLevelSelection(
    BuildContext context, {
    required int? currentLevel,
    required ValueChanged<int?> onLevelSelected,
  }) {
    return showCustomBottomSheet<void>(
      context: context,
      child: LevelSelectionBottomSheet(
        currentLevel: currentLevel,
        onLevelSelected: onLevelSelected,
      ),
    );
  }
}
