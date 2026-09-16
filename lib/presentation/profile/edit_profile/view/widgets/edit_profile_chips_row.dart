part of '../edit_profile_view.dart';

enum EditProfileChipVariant { preferred, negative }

/// Tercih / atlanan yiyecek satırı (ikon + label + chip’ler).
final class EditProfileChipsRow extends StatelessWidget {
  const EditProfileChipsRow({
    required this.icon,
    required this.title,
    required this.chips,
    this.variant = EditProfileChipVariant.preferred,
    this.onTap,
    super.key,
  });

  final SvgGenImage icon;
  final String title;
  final List<String> chips;
  final EditProfileChipVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isNegative = variant == EditProfileChipVariant.negative;

    return Material(
      color: ColorName.colorWhite,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: icon.svg(
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    ColorName.colorTitle,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.editProfileLabel),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final chip in chips)
                          _EditProfileChip(
                            label: chip,
                            isNegative: isNegative,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EditProfileChip extends StatelessWidget {
  const _EditProfileChip({required this.label, required this.isNegative});

  final String label;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNegative
            ? ColorName.colorOptionNegative.withValues(alpha: 0.15)
            : ColorName.colorHomeChipBg,
        borderRadius: BorderRadius.circular(99999),
      ),
      child: Text(
        label,
        style: isNegative
            ? AppTextStyles.editProfileChipNegative
            : AppTextStyles.editProfileChip,
      ),
    );
  }
}
