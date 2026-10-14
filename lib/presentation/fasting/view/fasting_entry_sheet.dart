import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Oruç geçmişi kaydı: başlangıç / bitiş düzenle, sil ya da geçmiş oruç ekle.
sealed class FastEntryAction {
  const FastEntryAction();
}

final class FastEntrySave extends FastEntryAction {
  const FastEntrySave(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

final class FastEntryDelete extends FastEntryAction {
  const FastEntryDelete();
}

/// [canDelete] false ise yeni kayıt ("Geçmiş oruç ekle").
final class FastEntrySheet extends StatefulWidget {
  const FastEntrySheet({
    required this.start,
    required this.end,
    required this.canDelete,
    super.key,
  });

  final DateTime start;
  final DateTime end;
  final bool canDelete;

  @override
  State<FastEntrySheet> createState() => _FastEntrySheetState();
}

class _FastEntrySheetState extends State<FastEntrySheet> {
  late DateTime _start = widget.start;
  late DateTime _end = widget.end;

  /// Sunucu sınırları: son 30 gün, en fazla 72 saat.
  String? get _error {
    final duration = _end.difference(_start);
    if (!duration.isNegative && duration.inMinutes >= 60) {
      if (duration.inHours > 72) return 'fasting_history_page.entry_too_long';
      return null;
    }
    return 'fasting_history_page.entry_invalid';
  }

  Future<void> _pick({required bool start}) async {
    final result = await AppDialogs.instance.showMealDatePicker(
      context,
      initialDate: start ? _start : _end,
      includeTime: true,
      maxDaysBack: 30,
    );
    if (result == null || !mounted) return;
    setState(() => start ? _start = result.date : _end = result.date);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final error = _error;
    final format = DateFormat.MMMd(context.locale.toString()).add_Hm();
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.canDelete
                  ? 'fasting_history_page.entry_edit_title'.tr()
                  : 'fasting_history_page.entry_add_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingEndTitle,
            ),
            const SizedBox(height: 16),
            _TimeRow(
              label: 'fasting_history_page.entry_start'.tr(),
              value: format.format(_start),
              onTap: () => _pick(start: true),
            ),
            const SizedBox(height: 8),
            _TimeRow(
              label: 'fasting_history_page.entry_end'.tr(),
              value: format.format(_end),
              onTap: () => _pick(start: false),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.tr(),
                style: AppTextStyles.fastingEndBody.copyWith(
                  color: ColorName.colorOptionNegative,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'hunger_log_page.save'.tr(),
              showIcon: false,
              isEnabled: error == null,
              decoration: AppButtonDecoration.homeJoin(),
              onPressed: () =>
                  Navigator.of(context).pop(FastEntrySave(_start, _end)),
            ),
            if (widget.canDelete) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(const FastEntryDelete()),
                child: Text(
                  'fasting_history_page.entry_delete'.tr(),
                  style: AppTextStyles.fastingEndBody.copyWith(
                    color: ColorName.colorOptionNegative,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorProfileBack,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.fastingEndBody)),
              Text(value, style: AppTextStyles.bodyHistoryTitleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
