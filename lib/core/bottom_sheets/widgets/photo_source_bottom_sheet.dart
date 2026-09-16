import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Kamera / galeri seçimi — profil kart stiline uyumlu.
final class PhotoSourceBottomSheet extends StatelessWidget {
  const PhotoSourceBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ColorName.colorProfileBack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorName.colorTitle.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'profile.change_photo'.tr(),
                    style: AppTextStyles.profileSectionTitle,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: ColorName.colorWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _PhotoSourceRow(
                      icon: Icons.photo_camera_outlined,
                      title: 'profile.photo_camera'.tr(),
                      onTap: () => Navigator.of(context).pop(
                        ImageSource.camera,
                      ),
                    ),
                    Divider(
                      height: 2,
                      thickness: 2,
                      indent: 8,
                      endIndent: 8,
                      color: ColorName.colorTitle.withValues(alpha: 0.06),
                    ),
                    _PhotoSourceRow(
                      icon: Icons.photo_library_outlined,
                      title: 'profile.photo_gallery'.tr(),
                      onTap: () =>
                          Navigator.of(context).pop(ImageSource.gallery),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: ColorName.colorWhite,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Center(
                      child: Text(
                        'profile.photo_cancel'.tr(),
                        style: AppTextStyles.profileLogout.copyWith(
                          color: ColorName.colorTitle.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
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

final class _PhotoSourceRow extends StatelessWidget {
  const _PhotoSourceRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Icon(icon, size: 22, color: ColorName.colorTitle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: AppTextStyles.profileRowTitle),
              ),
              Assets.icons.solarAltArrowLeftLinear.svg(
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  ColorName.colorTitle.withValues(alpha: 0.5),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
