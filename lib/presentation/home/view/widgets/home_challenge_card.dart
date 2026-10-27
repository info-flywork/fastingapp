part of '../home_view.dart';

/// Öne çıkan challenge (`/user/summary.featuredChallenge`); yoksa gizli.
final class HomeChallengeCard extends StatelessWidget {
  const HomeChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeBloc, HomeState, Challenge?>(
      bloc: getIt<HomeBloc>(),
      selector: (state) =>
          state is HomeLoaded ? state.summary?.featuredChallenge : null,
      builder: (context, challenge) {
        if (challenge == null) return const SizedBox.shrink();
        // Detay sayfası dokununca beklemeden açılsın (dakikada en çok bir kez).
        unawaited(prefetchChallengeDetail(challenge));
        return _ChallengeCardBody(challenge: challenge);
      },
    );
  }
}

final class _ChallengeCardBody extends StatelessWidget {
  const _ChallengeCardBody({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    // Karta dokununca detay sayfası (katılımcılar, ilerleme, görünürlük).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          context.pushNamed(RoutePaths.challengeDetail.name, extra: challenge),
      child: Container(
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
                AppImages.challenge.image(width: 28, height: 28),
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
                AppImages.fastingChallenge.image(
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
                        challenge.title,
                        style: AppTextStyles.homeChallengeTitle,
                      ),
                      if (challenge.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          challenge.subtitle,
                          style: AppTextStyles.homeChallengeSubtitle,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ParticipantsCluster(
                  count: challenge.participantsCount,
                  avatars: challenge.participantAvatars,
                ),
                const SizedBox(width: 12),
                Expanded(child: _JoinNowButton(challenge: challenge)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatarlar + "kişi katıldı" pill — son avatar pill'in üstüne biner.
final class _ParticipantsCluster extends StatelessWidget {
  const _ParticipantsCluster({required this.count, required this.avatars});

  final int count;

  /// Sunucudaki katılımcı avatar URL'leri (en fazla 3 gösterilir).
  final List<String> avatars;
  static const _avatarSize = 40.0;
  static const _avatarOverlap = 12.0;
  static const _chipHeight = 28.0;
  static const _chipOverlap = 18.0;

  @override
  Widget build(BuildContext context) {
    final shown = avatars.take(3).toList();
    const step = _avatarSize - _avatarOverlap;
    final lastAvatarLeft = (shown.length - 1) * step;
    final chipLeft = shown.isEmpty
        ? 0.0
        : lastAvatarLeft + _avatarSize - _chipOverlap;
    final countText = NumberFormat.decimalPattern(
      context.locale.toString(),
    ).format(count);

    final full = 'home.already_in'.tr(args: [countText]);
    final index = full.indexOf(countText);

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
                TextSpan(
                  text: countText,
                  style: AppTextStyles.homeAlreadyInCount,
                ),
                TextSpan(text: full.substring(index + countText.length)),
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
              padding: EdgeInsets.fromLTRB(shown.isEmpty ? 12 : 20, 4, 12, 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ColorName.colorHomeChipBg,
                borderRadius: BorderRadius.circular(_chipHeight / 2),
              ),
              child: label,
            ),
          ),
          for (var i = 0; i < shown.length; i++)
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
                child: ClipOval(
                  child: Image.network(
                    shown[i],
                    fit: BoxFit.cover,
                    cacheWidth: 120,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: ColorName.colorHomeChipBg),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _JoinNowButton extends StatefulWidget {
  const _JoinNowButton({required this.challenge});

  final Challenge challenge;

  @override
  State<_JoinNowButton> createState() => _JoinNowButtonState();
}

class _JoinNowButtonState extends State<_JoinNowButton> {
  bool _joining = false;

  /// Katıl → `POST /challenges/:code/join`; premium challenge'da 402 →
  /// paywall → tekrar. Sonra özet yenilenir (kart "x/y" gösterir).
  Future<void> _join() async {
    if (_joining) return;
    setState(() => _joining = true);
    final code = widget.challenge.code;
    final repo = getIt<ChallengesRepository>();
    try {
      Challenge? joined;
      try {
        joined = await repo.join(code);
      } on NetworkException catch (e) {
        if (!RevenueCatService.needsUpgrade(e)) rethrow;
        final revenueCat = getIt<RevenueCatService>();
        if (!await revenueCat.presentPaywall()) return;
        joined = await revenueCat.retryAfterUpgrade(() => repo.join(code));
      }
      // Yanıttaki challenge kartta hemen görünür; yazma sinyali yoldaki
      // eski özetin "Şimdi Katıl"a geri çevirmesini engeller.
      if (joined != null) getIt<HomeBloc>().add(HomeChallengeUpdated(joined));
      DataSync.afterWrite();
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _leave() async {
    final ok = await AppDialogs.instance.showLeaveChallenge(context);
    if (ok != true || !mounted) return;
    setState(() => _joining = true);
    try {
      await getIt<ChallengesRepository>().leave(widget.challenge.code);
      DataSync.afterWrite();
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final my = widget.challenge.my;
    if (widget.challenge.joined && my != null) {
      return AppButton(
        label: 'home.challenge_progress'.tr(
          args: ['${my.progress}', '${my.target}'],
        ),
        // Dokununca ayrılma onayı (önceden ayrılmanın yolu yoktu).
        onPressed: _joining ? null : () => unawaited(_leave()),
        decoration: AppButtonDecoration.homeJoin(),
        showIcon: false,
      );
    }
    return AppButton(
      label: 'home.join_now'.tr(),
      onPressed: _joining ? null : () => unawaited(_join()),
      decoration: AppButtonDecoration.homeJoin(),
      showIcon: false,
    );
  }
}
