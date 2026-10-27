import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/app_shimmer.dart';
import 'package:fastingapp/domain/gamification/challenges_repository.dart';
import 'package:fastingapp/domain/profile/profile_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Ana sayfa → Aktif meydan okuma kartı → detay: kurallar, ilerlemen,
/// görünürlük rızası ve katılımcı listesi (`GET /challenges/:code[/participants]`).
/// Son görülen sayfa verisi (oturum boyunca): sayfa yeniden açılınca hemen
/// gösterilir, arka planda sessizce tazelenir.
typedef _Snapshot = ({
  Challenge challenge,
  ChallengeParticipants participants,
  bool showMe,
});
final _cache = <String, _Snapshot>{};
final _prefetchedAt = <String, DateTime>{};

/// Sayfa verisini önbelleğe çeker (sonuç [_load] ile aynı). Ana sayfa kartı
/// görünürken çağrılır; karta dokunulduğunda sayfa beklemeden dolu açılır.
/// Bir dakika içinde tekrar çağrılırsa istek atmaz.
Future<void> prefetchChallengeDetail(Challenge challenge) async {
  final code = challenge.code;
  final last = _prefetchedAt[code];
  final now = DateTime.now();
  if (last != null && now.difference(last) < const Duration(minutes: 1)) {
    return;
  }
  _prefetchedAt[code] = now;
  try {
    await _fetchSnapshot(challenge);
  } on Object {
    // Sessiz: sayfa açılınca kendi yüklemesini yapar.
    _prefetchedAt.remove(code);
  }
}

/// Detay, katılımcılar ve görünürlük ayarı paralel; Future.wait ilk hatayı
/// olduğu gibi iletir (bağlantı mesajı kaybolmaz). Sonuç önbelleğe yazılır.
Future<_Snapshot> _fetchSnapshot(Challenge fallback) async {
  final code = fallback.code;
  final repo = getIt<ChallengesRepository>();
  final challengeF = repo.get(code);
  final participantsF = repo.participants(code);
  final settingsF = getIt<ProfileRepository>().getSettings();
  await Future.wait([challengeF, participantsF, settingsF]);
  final snapshot = (
    challenge: await challengeF ?? fallback,
    participants: await participantsF,
    showMe: (await settingsF).showInChallenges,
  );
  return _cache[code] = snapshot;
}

final class ChallengeDetailView extends StatefulWidget {
  const ChallengeDetailView({required this.initial, super.key});

  /// Karttan gelen challenge; sayfa açılınca sunucudan tazelenir.
  final Challenge initial;

  @override
  State<ChallengeDetailView> createState() => _ChallengeDetailViewState();
}

class _ChallengeDetailViewState extends State<ChallengeDetailView> {
  late final _Snapshot? _cached = _cache[widget.initial.code];
  late Challenge _challenge = _cached?.challenge ?? widget.initial;
  late ChallengeParticipants? _participants = _cached?.participants;
  late bool? _showMe = _cached?.showMe;
  var _busy = false;
  String? _error;

  ChallengesRepository get _repo => getIt<ChallengesRepository>();
  ProfileRepository get _profile => getIt<ProfileRepository>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final snapshot = await _fetchSnapshot(_challenge);
      if (!mounted) return;
      setState(() {
        _challenge = snapshot.challenge;
        _participants = snapshot.participants;
        _showMe = snapshot.showMe;
      });
    } on Object catch (e) {
      // Önbellekten gösterilen veri varsa sessiz kal; yoksa hata + tekrar dene.
      if (mounted && _participants == null) {
        setState(() => _error = errorMessageOf(e));
      }
    }
  }

  /// Katılım/ayrılma/rıza sonrası sayfa + ana sayfa kartı yenilenir.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      // Yazma sinyali: ana sayfa kartı tazelenir, yoldaki eski özet ezmez.
      DataSync.afterWrite();
      await _load();
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Premium challenge'da 402 → paywall → tekrar (ana sayfa kartıyla aynı).
  Future<void> _join() => _run(() async {
    final code = _challenge.code;
    Challenge? joined;
    try {
      joined = await _repo.join(code);
    } on NetworkException catch (e) {
      if (!RevenueCatService.needsUpgrade(e)) rethrow;
      final revenueCat = getIt<RevenueCatService>();
      if (!await revenueCat.presentPaywall()) return;
      joined = await revenueCat.retryAfterUpgrade(() => _repo.join(code));
    }
    // Ana sayfa kartı da sunucu özetini beklemeden "x/y" göstersin.
    if (joined != null) getIt<HomeBloc>().add(HomeChallengeUpdated(joined));
  });

  Future<void> _leave() async {
    final ok = await AppDialogs.instance.showLeaveChallenge(context);
    if (ok != true || !mounted) return;
    await _run(() => _repo.leave(_challenge.code));
  }

  Future<void> _setShowMe(bool value) async {
    final previous = _showMe;
    setState(() => _showMe = value);
    try {
      await _profile.updateSettings(showInChallenges: value);
      await _load();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _showMe = previous);
      AppSnackbar.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final participants = _participants;
    final my = _challenge.my;
    final joined = _challenge.joined && my != null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: () => context.pop()),
                    Expanded(
                      child: Text(
                        'challenge_page.title'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyHistoryTitleSmall,
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 24),
                    children: [
                      _HeroCard(challenge: _challenge),
                      const SizedBox(height: 12),
                      if (joined)
                        _ProgressCard(progress: my)
                      else
                        AppButton(
                          label: 'home.join_now'.tr(),
                          onPressed: _busy ? null : () => unawaited(_join()),
                          decoration: AppButtonDecoration.homeJoin(),
                          showIcon: false,
                        ),
                      if (_showMe != null) ...[
                        const SizedBox(height: 12),
                        _VisibilityCard(
                          value: _showMe!,
                          onChanged: (v) => unawaited(_setShowMe(v)),
                        ),
                      ] else if (_error == null) ...[
                        const SizedBox(height: 12),
                        const AppShimmer(
                          child: AppShimmerBone(
                            height: 96,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _SectionHeader(
                        count:
                            participants?.total ?? _challenge.participantsCount,
                      ),
                      const SizedBox(height: 8),
                      if (participants == null && _error == null)
                        const _ParticipantsSkeleton()
                      else if (participants == null)
                        _ErrorBody(message: _error!, onRetry: _load)
                      else
                        _ParticipantsList(data: participants),
                      if (joined && !my.completed) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: _busy ? null : () => unawaited(_leave()),
                            child: Text(
                              'challenge_page.leave'.tr(),
                              style: AppTextStyles.fastingEndBody.copyWith(
                                color: ColorName.colorOptionNegative,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

final class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

/// Rozet, başlık, açıklama ve süre / ödül / premium çipleri.
final class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final description = challenge.description;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppImages.fastingChallenge.image(
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: AppTextStyles.homeChallengeTitle,
                    ),
                    if (challenge.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
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
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(description, style: AppTextStyles.profileRowSubtitle),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (challenge.durationDays > 0)
                _Chip(
                  text: 'challenge_page.duration_days'.tr(
                    args: ['${challenge.durationDays}'],
                  ),
                ),
              if (challenge.rewardXp > 0)
                _Chip(
                  text: 'challenge_page.reward_xp'.tr(
                    args: ['${challenge.rewardXp}'],
                  ),
                ),
              if (challenge.isPremium) const _Chip(text: 'Premium'),
            ],
          ),
        ],
      ),
    );
  }
}

final class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorName.colorHomeChipBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: AppTextStyles.homeAlreadyInCount),
    );
  }
}

/// Katıldıysa: ilerleme çubuğu + kalan gün (ya da tamamlandı).
final class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final ChallengeProgress progress;

  @override
  Widget build(BuildContext context) {
    final target = math.max(progress.target, 1);
    final ratio = (progress.progress / target).clamp(0.0, 1.0);
    final end = progress.windowEnd;
    final daysLeft = end == null
        ? null
        : end.difference(DateTime.now()).inHours / 24;
    final caption = progress.completed
        ? 'challenge_page.completed'.tr()
        : daysLeft == null
        ? null
        : daysLeft < 1
        ? 'challenge_page.ends_today'.tr()
        : 'challenge_page.days_left'.tr(args: ['${daysLeft.floor()}']);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'challenge_page.my_progress'.tr(),
                  style: AppTextStyles.profileSectionTitle,
                ),
              ),
              Text(
                'home.challenge_progress'.tr(
                  args: ['${progress.progress}', '${progress.target}'],
                ),
                style: AppTextStyles.profileSectionTitle,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Bar(ratio: ratio, height: 10),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              style: AppTextStyles.profileRowSubtitle.copyWith(
                color: progress.completed ? ColorName.colorToggleOn : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _Bar extends StatelessWidget {
  const _Bar({required this.ratio, this.height = 6});

  final double ratio;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: ColorName.colorPlanArcTrack),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: const ColoredBox(color: ColorName.colorToggleOn),
            ),
          ],
        ),
      ),
    );
  }
}

/// Açık rıza: listede ad + fotoğraf görünsün mü (varsayılan kapalı).
final class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'challenge_page.visibility_title'.tr(),
                  style: AppTextStyles.profileRowTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  'challenge_page.visibility_body'.tr(),
                  style: AppTextStyles.profileRowSubtitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.85,
            alignment: Alignment.centerRight,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: ColorName.colorToggleOn,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final countText = NumberFormat.decimalPattern(
      context.locale.toString(),
    ).format(count);
    return Row(
      children: [
        Text(
          'challenge_page.participants_title'.tr(),
          style: AppTextStyles.notificationsDate,
        ),
        const Spacer(),
        Text(
          'home.already_in'.tr(args: [countText]),
          style: AppTextStyles.homeAlreadyIn,
        ),
      ],
    );
  }
}

/// İlk açılışta (önbellek yokken) katılımcı satırlarının iskeleti.
final class _ParticipantsSkeleton extends StatelessWidget {
  const _ParticipantsSkeleton();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: AppShimmer(
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              const Row(
                children: [
                  AppShimmerBone(width: 24, height: 14),
                  SizedBox(width: 8),
                  AppShimmerBone(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppShimmerBone(width: 120, height: 14),
                        SizedBox(height: 10),
                        AppShimmerBone(height: 6),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  AppShimmerBone(width: 28, height: 14),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _ParticipantsList extends StatelessWidget {
  const _ParticipantsList({required this.data});

  final ChallengeParticipants data;

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'challenge_page.empty'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.profileRowSubtitle,
        ),
      );
    }
    final hidden = data.total - data.items.length;
    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < data.items.length; i++) ...[
            if (i > 0)
              const Divider(height: 20, color: ColorName.colorHomeChipBg),
            _ParticipantRow(item: data.items[i]),
          ],
          if (hidden > 0) ...[
            const SizedBox(height: 12),
            Text(
              'challenge_page.more'.tr(args: ['$hidden']),
              style: AppTextStyles.profileRowSubtitle,
            ),
          ],
        ],
      ),
    );
  }
}

final class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.item});

  final ChallengeParticipant item;

  /// Rızasız katılımcılar için maskot avatarları (sıraya göre dönüşümlü).
  static final _mascots = [
    AppImages.fastingChallengeUser1,
    AppImages.fastingChallengeUser2,
    AppImages.fastingChallengeUser3,
  ];

  @override
  Widget build(BuildContext context) {
    final target = math.max(item.target, 1);
    final name = item.displayName ?? 'challenge_page.anonymous'.tr();
    final mascot = _mascots[item.rank % _mascots.length];
    final url = item.avatarUrl;
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '${item.rank}',
            textAlign: TextAlign.center,
            style: AppTextStyles.profileRowSubtitle,
          ),
        ),
        const SizedBox(width: 8),
        ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    cacheWidth: 120,
                    errorBuilder: (_, _, _) => mascot.image(fit: BoxFit.cover),
                  )
                : mascot.image(fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.profileRowTitle,
                    ),
                  ),
                  if (item.isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ColorName.colorHungerGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'challenge_page.you'.tr(),
                        style: AppTextStyles.homeAlreadyInCount.copyWith(
                          color: ColorName.colorPhysicalHungerBadgeText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _Bar(ratio: (item.progress / target).clamp(0.0, 1.0)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (item.completed)
          Assets.icons.solarVerifiedCheckBold.svg(width: 22, height: 22)
        else
          Text(
            '${item.progress}/${item.target}',
            style: AppTextStyles.profileSectionTitle,
          ),
      ],
    );
  }
}

final class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.profileRowSubtitle,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => unawaited(onRetry()),
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }
}

final class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
