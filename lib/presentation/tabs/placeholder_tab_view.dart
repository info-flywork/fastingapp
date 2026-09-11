import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Henüz tasarımı gelmemiş tab ekranı için hafif placeholder.
final class PlaceholderTabView extends StatelessWidget {
  const PlaceholderTabView({required this.titleKey, super.key});

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorProfileBack,
      body: SafeArea(
        child: Center(
          child: Text(titleKey.tr(), style: AppTextStyles.homeCardTitle),
        ),
      ),
    );
  }
}
