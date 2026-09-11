import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Ana shell alt navigasyonu — 5 sekme, PNG ikonlar.
final class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItem>[
    _NavItem(labelKey: 'home.nav_home', iconBuilder: _homeIcon),
    _NavItem(labelKey: 'home.nav_fasting', iconBuilder: _fastingIcon),
    _NavItem(labelKey: 'home.nav_plans', iconBuilder: _plansIcon),
    _NavItem(labelKey: 'home.nav_insights', iconBuilder: _insightsIcon),
    _NavItem(labelKey: 'home.nav_profile', iconBuilder: _profileIcon),
  ];

  static Widget _homeIcon(double size) =>
      Assets.images.home.image(width: size, height: size);
  static Widget _fastingIcon(double size) =>
      Assets.images.fasting.image(width: size, height: size);
  static Widget _plansIcon(double size) =>
      Assets.images.plans.image(width: size, height: size);
  static Widget _insightsIcon(double size) =>
      Assets.images.insights.image(width: size, height: size);
  static Widget _profileIcon(double size) =>
      Assets.images.profile.image(width: size, height: size);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 10, 8, bottom > 0 ? bottom : 10),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavTile(
                  item: _items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _NavItem {
  const _NavItem({required this.labelKey, required this.iconBuilder});

  final String labelKey;
  final Widget Function(double size) iconBuilder;
}

final class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = selected ? 1.0 : 0.5;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            item.iconBuilder(28),
            const SizedBox(height: 4),
            Text(item.labelKey.tr(), style: AppTextStyles.navLabel),
          ],
        ),
      ),
    );
  }
}
