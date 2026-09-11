part of '../home_view.dart';

/// Aktif challenge kartı.
final class HomeChallengeCard extends StatelessWidget {
  const HomeChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Assets.images.challenge.image(width: 20, height: 20),
              const SizedBox(width: 6),
              Text(
                'home.active_challenge'.tr(),
                style: AppTextStyles.homeChallengeEyebrow,
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: ColorName.colorSubtitle.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Assets.images.fastingChallenge.image(
                width: 64,
                height: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.challenge_title'.tr(),
                      style: AppTextStyles.homeChallengeTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'home.challenge_subtitle'.tr(),
                      style: AppTextStyles.homeChallengeSubtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const _AvatarStack(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'home.already_in'.tr(args: ['8954']),
                  style: AppTextStyles.homeAlreadyIn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const _JoinNowButton(),
            ],
          ),
        ],
      ),
    );
  }
}

final class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    final avatars = [
      Assets.images.fastingChallengeUser1,
      Assets.images.fastingChallengeUser2,
      Assets.images.fastingChallengeUser3,
    ];

    return SizedBox(
      width: 72,
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < avatars.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorName.colorWhite, width: 2),
                ),
                child: ClipOval(
                  child: avatars[i].image(fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _JoinNowButton extends StatelessWidget {
  const _JoinNowButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [
            ColorName.colorCtaGradientTop,
            ColorName.colorCtaGradientBottom,
          ],
        ),
        border: Border.all(
          color: ColorName.colorWhite.withValues(alpha: 0.15),
        ),
      ),
      child: Text('home.join_now'.tr(), style: AppTextStyles.homeJoinNow),
    );
  }
}
