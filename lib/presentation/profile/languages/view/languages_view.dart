import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/managers/localization_manager.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/profile/languages/languages_catalog.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dil seçim ekranı.
final class LanguagesView extends StatefulWidget {
  const LanguagesView({super.key});

  @override
  State<LanguagesView> createState() => _LanguagesViewState();
}

class _LanguagesViewState extends State<LanguagesView> {
  late String _selectedCode = context.locale.languageCode;

  Future<void> _onSelect(AppLanguageOption option) async {
    setState(() => _selectedCode = option.code);
    if (LocalizationManager.isSupported(option.locale)) {
      await context.setLocale(option.locale);
    }
    if (!mounted) return;

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorProfileBack,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: EditProfileAppBar(
                title: 'languages.title'.tr(),
                onBack: () => context.pop(),
                backButtonColor: ColorName.colorWhite,
              ),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
                  // Frame 48096383 — tüm dilleri saran container
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ColorName.colorWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < LanguagesCatalog.options.length;
                            i++
                          ) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _LanguageCard(
                              option: LanguagesCatalog.options[i],
                              isSelected:
                                  LanguagesCatalog.options[i].code ==
                                  _selectedCode,
                              onTap: () =>
                                  _onSelect(LanguagesCatalog.options[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frame 48096357 — tek dil kartı.
final class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final AppLanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: ColorName.colorWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 2,
              color: ColorName.colorBlack.withValues(alpha: 0.05),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: option.flag.svg(
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.nameKey.tr(),
                    style: AppTextStyles.notificationsCardTitle,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorName.colorOptionSelected,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: ColorName.colorWhite,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
