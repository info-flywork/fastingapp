part of '../profile_view.dart';

/// Beyaz menü kartı (Account / Activity / Support).
final class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 2,
                thickness: 2,
                indent: 8,
                endIndent: 8,
                color: ColorName.colorTitle.withValues(alpha: 0.06),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Switch olmayan satırlarda sağ ok.
Widget _profileChevron() {
  return Assets.icons.solarAltArrowLeftLinear.svg(
    width: 20,
    height: 20,
    colorFilter: ColorFilter.mode(
      ColorName.colorTitle.withValues(alpha: 0.5),
      BlendMode.srcIn,
    ),
  );
}

/// Tek menü satırı.
final class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleStyle,
    this.iconColor,
    super.key,
  });

  final SvgGenImage icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? ColorName.colorTitle;
    final showChevron = trailing == null;

    return Material(
      color: ColorName.colorWhite,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 14, 12, subtitle != null ? 20 : 14),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: icon.svg(
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: titleStyle ?? AppTextStyles.profileRowTitle,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.profileRowSubtitle),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (showChevron) _profileChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Çıkış yap — Figma: dış p8/r16, iç 56h/r14/p12, border black 5% 2px.
final class ProfileLogoutCard extends StatelessWidget {
  const ProfileLogoutCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 56,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                width: 2,
                color: ColorName.colorTitle.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Assets.icons.solarLogout2LineDuotone.svg(
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    ColorName.colorOptionNegative,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'profile.log_out'.tr(),
                    style: AppTextStyles.profileLogout,
                  ),
                ),
                _profileChevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
