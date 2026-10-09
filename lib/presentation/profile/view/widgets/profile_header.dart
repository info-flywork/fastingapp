part of '../profile_view.dart';

/// Avatar + isim + Premium badge + streak + AI chat.
final class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.displayName,
    required this.initials,
    required this.streakDays,
    required this.isPremium,
    required this.onChatTapped,
    this.avatarUrl,
    this.localPhotoPath,
    super.key,
  });

  final String displayName;
  final String initials;
  final String? avatarUrl;

  /// Yeni seçilen, yüklenmekte olan fotoğraf (öncelikli).
  final String? localPhotoPath;
  final int streakDays;
  final bool isPremium;
  final VoidCallback onChatTapped;

  /// Baş harfler; ad yoksa kişi simgesi.
  Widget _initialsText() => initials.isEmpty
      ? const Icon(Icons.person_rounded, color: ColorName.colorWhite, size: 26)
      : Text(
          initials,
          style: AppTextStyles.profileName.copyWith(
            color: ColorName.colorWhite,
            fontSize: 16,
            height: 1,
          ),
        );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: ColorName.colorTitle,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: localPhotoPath != null
              ? Image.file(
                  File(localPhotoPath!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                )
              : avatarUrl != null
              ? Image.network(
                  avatarUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _initialsText(),
                )
              : _initialsText(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: AppTextStyles.profileName),
              if (isPremium) ...[
                const SizedBox(height: 6),
                const _PremiumBadge(),
              ],
            ],
          ),
        ),
        _StreakPill(streakDays: streakDays),
        const SizedBox(width: 10),
        AiChatHeaderIcon(onTap: onChatTapped),
      ],
    );
  }
}

final class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.circular(4),
        ),
        gradient: const LinearGradient(
          colors: [
            ColorName.colorPremiumGradientStart,
            ColorName.colorPremiumGradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        'profile.premium_badge'.tr(),
        style: AppTextStyles.profilePremiumBadge,
      ),
    );
  }
}

final class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppImages.streakFlame.image(
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                ColorName.colorStreakGradientStart,
                ColorName.colorStreakGradientEnd,
              ],
            ).createShader(bounds),
            child: Text('$streakDays', style: AppTextStyles.homeStreakCount),
          ),
        ],
      ),
    );
  }
}
