import 'dart:math' as math;

import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Edit Profile alt sayfaları için geri + ortalı başlık.
final class EditProfileAppBar extends StatelessWidget {
  const EditProfileAppBar({
    required this.title,
    required this.onBack,
    this.backButtonColor,
    super.key,
  });

  final String title;
  final VoidCallback onBack;

  /// null → [ColorName.colorFlipClock] (beyaz ekranlarda).
  final Color? backButtonColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: backButtonColor ?? ColorName.colorFlipClock,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Transform.rotate(
                      angle: math.pi,
                      child: Assets.icons.solarAltArrowLeftLinear.svg(
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          ColorName.colorTitle,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(title, style: AppTextStyles.selectionSheetTitle),
        ],
      ),
    );
  }
}
