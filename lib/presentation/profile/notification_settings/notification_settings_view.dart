import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/core/widgets/app_loading.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:fastingapp/presentation/profile/view/widgets/profile_menu_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Profil → Bildirim ayarları: kategori bazında push ve sessiz saatler
/// (`GET/PATCH /user/settings`). Önceden yalnızca genel push anahtarı vardı.
final class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  static const _categories = [
    ('fasting', 'notification_settings.fasting'),
    ('streak', 'notification_settings.streak'),
    ('weight', 'notification_settings.weight'),
    ('water', 'notification_settings.water'),
    ('challenges', 'notification_settings.challenges'),
    ('world', 'notification_settings.world'),
  ];

  Map<String, bool> _flags = const {};
  String _quietStart = '22:30';
  String _quietEnd = '08:00';
  var _loading = true;

  NetworkManager get _network => getIt<NetworkManager>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final s = await _network.send<_Settings>(
        path: '/user/settings',
        method: RequestType.get,
        parserModel: _Settings.fromJson,
      );
      if (!mounted || s == null) return;
      setState(() {
        _flags = s.flags;
        _quietStart = s.quietStart;
        _quietEnd = s.quietEnd;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackbar.showError(context, e);
    }
  }

  Future<void> _patch(
    Map<String, dynamic> fields,
    VoidCallback rollback,
  ) async {
    try {
      await _network.send<_Settings>(
        path: '/user/settings',
        method: RequestType.patch,
        data: fields,
        parserModel: _Settings.fromJson,
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(rollback);
      AppSnackbar.showError(context, e);
    }
  }

  void _toggle(String key, bool value) {
    final previous = _flags[key];
    setState(() => _flags = {..._flags, key: value});
    unawaited(
      _patch({
        'notifications': {key: value},
      }, () => _flags = {..._flags, key: previous ?? !value}),
    );
  }

  static (int, int) _hm(String v) {
    final p = v.split(':');
    return (
      int.tryParse(p.first) ?? 0,
      p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0,
    );
  }

  static String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _editQuietHours() async {
    final (sh, sm) = _hm(_quietStart);
    final (eh, em) = _hm(_quietEnd);
    final result = await AppDialogs.instance.showQuietHours(
      context,
      startHour: sh,
      startMinute: sm,
      endHour: eh,
      endMinute: em,
    );
    if (result == null || !mounted) return;
    final start = _fmt(result.startHour, result.startMinute);
    final end = _fmt(result.endHour, result.endMinute);
    final (ps, pe) = (_quietStart, _quietEnd);
    setState(() {
      _quietStart = start;
      _quietEnd = end;
    });
    await _patch(
      {
        'quietHours': {'start': start, 'end': end},
      },
      () {
        _quietStart = ps;
        _quietEnd = pe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorProfileBack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: EditProfileAppBar(
                title: 'notification_settings.title'.tr(),
                onBack: () => context.pop(),
                backButtonColor: ColorName.colorWhite,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: AppLoading())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                      children: [
                        ProfileMenuCard(
                          children: [
                            for (final (key, label) in _categories)
                              ProfileMenuRow(
                                icon: Assets.icons.solarBellLineDuotone,
                                title: label.tr(),
                                trailing: Transform.scale(
                                  scale: 0.85,
                                  alignment: Alignment.centerRight,
                                  child: CupertinoSwitch(
                                    value: _flags[key] ?? key != 'water',
                                    activeTrackColor: ColorName.colorToggleOn,
                                    onChanged: (v) => _toggle(key, v),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ProfileMenuCard(
                          children: [
                            ProfileMenuRow(
                              icon: Assets.icons.solarClockCircleLineDuotone,
                              title: 'notification_settings.quiet_hours'.tr(),
                              subtitle: '$_quietStart – $_quietEnd',
                              onTap: () => unawaited(_editQuietHours()),
                            ),
                          ],
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

final class _Settings implements BaseModel<_Settings> {
  const _Settings({
    this.flags = const {},
    this.quietStart = '22:30',
    this.quietEnd = '08:00',
  });

  factory _Settings.fromJson(Map<String, dynamic> json) {
    final n = json['notifications'];
    final q = json['quietHours'];
    return _Settings(
      flags: {
        if (n is Map<String, dynamic>)
          for (final e in n.entries)
            if (e.value is bool) e.key: e.value as bool,
      },
      quietStart: q is Map<String, dynamic>
          ? q['start'] as String? ?? '22:30'
          : '22:30',
      quietEnd: q is Map<String, dynamic>
          ? q['end'] as String? ?? '08:00'
          : '08:00',
    );
  }

  final Map<String, bool> flags;
  final String quietStart;
  final String quietEnd;

  @override
  _Settings fromJson(Map<String, dynamic> json) => _Settings.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
