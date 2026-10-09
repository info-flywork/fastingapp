import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/dialogs/widgets/water_edit_dialog.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:fastingapp/presentation/water/reminder/water_reminder_result.dart';
import 'package:fastingapp/presentation/water/water_glass_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Su hatırlatıcı ayarları — bildirim, hedef, birim, bardak boyutu.
final class WaterReminderView extends StatefulWidget {
  const WaterReminderView({this.args, super.key});

  final WaterReminderArgs? args;

  @override
  State<WaterReminderView> createState() => _WaterReminderViewState();
}

class _WaterReminderViewState extends State<WaterReminderView> {
  static const _presetSizes = <int>[50, 100, 200, 300, 500];

  late bool _notificationsEnabled;
  late int _dailyGoalMl;
  late WaterVolumeUnit _unit;
  late int _glassSizeMl;
  late List<int> _customSizes;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    _notificationsEnabled = args?.notificationsEnabled ?? false;
    _dailyGoalMl = args?.dailyGoalMl ?? 2000;
    _unit = args?.unit == 'oz' ? WaterVolumeUnit.oz : WaterVolumeUnit.ml;
    _glassSizeMl = args?.glassSizeMl ?? 300;
    _customSizes = [
      ...?args?.customGlassSizes.where((ml) => !_presetSizes.contains(ml)),
      if (!_presetSizes.contains(_glassSizeMl) &&
          _glassSizeMl > 0 &&
          !(args?.customGlassSizes.contains(_glassSizeMl) ?? false))
        _glassSizeMl,
    ];
    unawaited(_loadNotificationPref());
  }

  Future<void> _loadNotificationPref() async {
    try {
      final settings = await getIt<TrackersRepository>().getSettings();
      if (!mounted) return;
      setState(() => _notificationsEnabled = settings.waterNotifications);
    } on Object {
      // Args / yerel değerle kal.
    }
  }

  List<int> get _allSizes => [..._presetSizes, ..._customSizes];

  String get _unitLabel => _unit == WaterVolumeUnit.ml ? 'ml' : 'oz';

  static const _mlPerOz = 29.5735295625;

  /// Hedef her zaman ml tutulur; etiket seçili birime çevrilir.
  String get _dailyGoalLabel {
    if (_unit == WaterVolumeUnit.ml) return '$_dailyGoalMl ml';
    final oz = _dailyGoalMl / _mlPerOz;
    final rounded = (oz * 10).round() / 10;
    final text = rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
    return '$text oz';
  }

  Future<void> _editDailyGoal() async {
    final result = await AppDialogs.instance.showEditWaterValue(
      context,
      titleKey: 'water_reminder.daily_goal',
      subtitleKey: 'water_reminder.goal_dialog_subtitle',
      initialValueMl: _dailyGoalMl,
      initialUnit: _unit,
      headerImage: AppImages.waterBottle,
    );
    if (result == null || !mounted) return;
    setState(() {
      _dailyGoalMl = result.valueMl;
      _unit = result.unit;
    });
  }

  Future<void> _editUnit() async {
    final result = await AppDialogs.instance.showEditWaterUnit(
      context,
      initialUnit: _unit,
    );
    if (result == null || !mounted) return;
    setState(() => _unit = result.unit);
  }

  Future<void> _addCustomSize() async {
    final result = await AppDialogs.instance.showEditWaterValue(
      context,
      titleKey: 'water_reminder.glass_size',
      subtitleKey: 'water_reminder.custom_size_dialog_subtitle',
      initialValueMl: _glassSizeMl,
      initialUnit: _unit,
      headerImage: AppImages.waterSizePlus,
    );
    if (result == null || !mounted) return;
    setState(() {
      if (!_allSizes.contains(result.valueMl)) {
        _customSizes = [..._customSizes, result.valueMl];
      }
      _glassSizeMl = result.valueMl;
      _unit = result.unit;
    });
  }

  void _save() {
    context.pop(
      WaterReminderResult(
        dailyGoalMl: _dailyGoalMl,
        glassSizeMl: _glassSizeMl,
        unit: _unitLabel,
        notificationsEnabled: _notificationsEnabled,
        customGlassSizes: List<int>.of(_customSizes),
      ),
    );
  }

  AppImageAsset _iconForSize(int ml) => WaterGlassIcons.forMl(ml);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorProfileBack,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: EditProfileAppBar(
                  title: 'water_reminder.title'.tr(),
                  onBack: () => context.pop(),
                  backButtonColor: ColorName.colorWhite,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  children: [
                    _NotificationCard(
                      enabled: _notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                    ),
                    const SizedBox(height: 16),
                    _SettingsCard(
                      dailyGoalLabel: _dailyGoalLabel,
                      unitLabel: _unitLabel,
                      glassSizeMl: _glassSizeMl,
                      sizes: _allSizes,
                      iconForSize: _iconForSize,
                      onEditGoal: _editDailyGoal,
                      onEditUnit: _editUnit,
                      onSelectSize: (ml) => setState(() => _glassSizeMl = ml),
                      onAddCustom: _addCustomSize,
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: ColorName.colorWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
                  child: AppButton(
                    label: 'water_reminder.save'.tr(),
                    onPressed: _save,
                    showIcon: false,
                    decoration: AppButtonDecoration.water(),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'water_reminder.notification'.tr(),
                style: AppTextStyles.waterReminderLabel,
              ),
            ),
            Transform.scale(
              scale: 0.9,
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 64,
                height: 32,
                child: FittedBox(
                  child: CupertinoSwitch(
                    value: enabled,
                    activeTrackColor: ColorName.colorWaterAction,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.dailyGoalLabel,
    required this.unitLabel,
    required this.glassSizeMl,
    required this.sizes,
    required this.iconForSize,
    required this.onEditGoal,
    required this.onEditUnit,
    required this.onSelectSize,
    required this.onAddCustom,
  });

  final String dailyGoalLabel;
  final String unitLabel;
  final int glassSizeMl;
  final List<int> sizes;
  final AppImageAsset? Function(int ml) iconForSize;
  final VoidCallback onEditGoal;
  final VoidCallback onEditUnit;
  final ValueChanged<int> onSelectSize;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingRow(
              label: 'water_reminder.daily_goal'.tr(),
              value: dailyGoalLabel,
              onEdit: onEditGoal,
            ),
            const SizedBox(height: 24),
            _SettingRow(
              label: 'water_reminder.units'.tr(),
              value: unitLabel,
              onEdit: onEditUnit,
            ),
            const SizedBox(height: 24),
            Text(
              'water_reminder.glass_size'.tr(),
              style: AppTextStyles.waterReminderLabel,
            ),
            const SizedBox(height: 16),
            _GlassSizeGrid(
              sizes: sizes,
              selectedMl: glassSizeMl,
              iconForSize: iconForSize,
              onSelect: onSelectSize,
              onAddCustom: onAddCustom,
            ),
          ],
        ),
      ),
    );
  }
}

final class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.waterReminderLabel)),
        Text(value, style: AppTextStyles.waterReminderValue),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AppImages.solarPenBold.image(width: 16, height: 16),
          ),
        ),
      ],
    );
  }
}

final class _GlassSizeGrid extends StatelessWidget {
  const _GlassSizeGrid({
    required this.sizes,
    required this.selectedMl,
    required this.iconForSize,
    required this.onSelect,
    required this.onAddCustom,
  });

  final List<int> sizes;
  final int selectedMl;
  final AppImageAsset? Function(int ml) iconForSize;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final ml in sizes)
        _GlassSizeTile(
          label: '$ml ml',
          selected: ml == selectedMl,
          icon: iconForSize(ml),
          onTap: () => onSelect(ml),
        ),
      _GlassSizeTile(
        label: null,
        selected: false,
        icon: AppImages.waterSizePlus,
        onTap: onAddCustom,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final tileW = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(width: tileW, height: tileW, child: item),
          ],
        );
      },
    );
  }
}

final class _GlassSizeTile extends StatelessWidget {
  const _GlassSizeTile({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String? label;
  final bool selected;
  final AppImageAsset? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ColorName.colorWhite : ColorName.colorWaterGlassTile,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  _GlassSizeIcon(
                    image: icon!,
                    vibrant: selected || label == null,
                  )
                else
                  const SizedBox(width: 56, height: 56),
                if (label != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    label!,
                    style: selected
                        ? AppTextStyles.waterGlassSizeLabelSelected
                        : AppTextStyles.waterGlassSizeLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seçili: tam canlı renk. Seçili değil: soluk.
final class _GlassSizeIcon extends StatelessWidget {
  const _GlassSizeIcon({required this.image, required this.vibrant});

  final AppImageAsset image;
  final bool vibrant;

  static const _mutedFilter = ColorFilter.matrix(<double>[
    0.55,
    0.35,
    0.10,
    0,
    18,
    0.35,
    0.55,
    0.10,
    0,
    22,
    0.25,
    0.30,
    0.55,
    0,
    35,
    0,
    0,
    0,
    0.72,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final child = image.image(width: 56, height: 56);
    if (vibrant) return child;
    return ColorFiltered(colorFilter: _mutedFilter, child: child);
  }
}
