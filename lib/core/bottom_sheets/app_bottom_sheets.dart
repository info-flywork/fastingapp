import 'package:fastingapp/core/bottom_sheets/bottom_sheet_handler.dart';
import 'package:fastingapp/core/bottom_sheets/widgets/edit_name_bottom_sheet.dart';
import 'package:fastingapp/core/bottom_sheets/widgets/level_selection_bottom_sheet.dart';
import 'package:fastingapp/core/bottom_sheets/widgets/photo_source_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  /// Kamera veya galeri seçimini döner; iptalde null.
  Future<ImageSource?> showPhotoSource(BuildContext context) {
    return showCustomBottomSheet<ImageSource>(
      context: context,
      heightFactor: null,
      child: const PhotoSourceBottomSheet(),
    );
  }

  /// İsmi düzenler; kaydedilirse yeni değeri, iptalde null döner.
  Future<String?> showEditName(
    BuildContext context, {
    required String initialName,
  }) {
    return showCustomBottomSheet<String>(
      context: context,
      heightFactor: null,
      child: EditNameBottomSheet(initialName: initialName),
    );
  }
}
