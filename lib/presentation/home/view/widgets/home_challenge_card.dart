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
              Assets.images.challenge.image(width: 28, height: 28),
              const SizedBox(width: 6),
              Text(
                'home.active_challenge'.tr(),
                style: AppTextStyles.homeChallengeEyebrow,
              ),
              const Spacer(),
              Assets.icons.solarAltArrowUpLineDuotoneRight.svg(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Assets.images.fastingChallenge.image(
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.challenge_title'.tr(),
                      style: AppTextStyles.homeChallengeTitle,
                    ),
                    const SizedBox(height: 8),
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
          const Row(
            children: [
              _ParticipantsCluster(),
              SizedBox(width: 12),
              Expanded(child: _JoinNowButton()),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avatarlar + "kişi katıldı" pill — son avatar pill'in üstüne biner.
final class _ParticipantsCluster extends StatelessWidget {
  const _ParticipantsCluster();

  static const _count = '8954';
  static const _avatarSize = 40.0;
  static const _avatarOverlap = 12.0;
  static const _chipHeight = 28.0;
  static const _chipOverlap = 18.0;

  @override
  Widget build(BuildContext context) {
    final avatars = [
      Assets.images.fastingChallengeUser1,
      Assets.images.fastingChallengeUser2,
      Assets.images.fastingChallengeUser3,
    ];
    const step = _avatarSize - _avatarOverlap;
    final lastAvatarLeft = (avatars.length - 1) * step;
    final chipLeft = lastAvatarLeft + _avatarSize - _chipOverlap;

    final full = 'home.already_in'.tr(args: [_count]);
    final index = full.indexOf(_count);

    final label = index < 0
        ? Text(
            full,
            style: AppTextStyles.homeAlreadyIn,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : Text.rich(
            TextSpan(
              style: AppTextStyles.homeAlreadyIn,
              children: [
                if (index > 0) TextSpan(text: full.substring(0, index)),
                TextSpan(text: _count, style: AppTextStyles.homeAlreadyInCount),
                TextSpan(text: full.substring(index + _count.length)),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    return SizedBox(
      height: _avatarSize,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Pill — stack genişliğini belirler; sol kenarı son avatarın altında.
          Padding(
            padding: EdgeInsets.only(left: chipLeft),
            child: Container(
              height: _chipHeight,
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ColorName.colorHomeChipBg,
                borderRadius: BorderRadius.circular(_chipHeight / 2),
              ),
              child: label,
            ),
          ),
          for (var i = 0; i < avatars.length; i++)
            Positioned(
              left: i * step,
              top: 0,
              child: Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorName.colorWhite, width: 2),
                ),
                child: ClipOval(child: avatars[i].image(fit: BoxFit.cover)),
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
    return AppButton(
      label: 'home.join_now'.tr(),
      onPressed: () {},
      decoration: AppButtonDecoration.homeJoin(),
      showIcon: false,
    );
  }
}
