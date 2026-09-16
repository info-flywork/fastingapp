part of '../edit_profile_view.dart';

/// Geri + başlık + avatar + Change photo.
final class EditProfileHeader extends StatelessWidget {
  const EditProfileHeader({
    required this.initials,
    required this.onBack,
    required this.onChangePhoto,
    this.photoPath,
    super.key,
  });

  final String initials;
  final String? photoPath;
  final VoidCallback onBack;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: ColorName.colorWhite,
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
              Text(
                'profile.edit_profile'.tr(),
                style: AppTextStyles.editProfileTitle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onChangePhoto,
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: ColorName.colorAvatarBg,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: photoPath != null
                ? Image.file(
                    File(photoPath!),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Text(initials, style: AppTextStyles.editProfileInitials),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onChangePhoto,
          behavior: HitTestBehavior.opaque,
          child: Text(
            'profile.change_photo'.tr(),
            style: AppTextStyles.editProfileChangePhoto,
          ),
        ),
      ],
    );
  }
}
