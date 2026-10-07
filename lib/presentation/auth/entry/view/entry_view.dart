import 'dart:math' as math;
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_text_button.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/domain/onboarding/onboarding_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'mixin/entry_view_mixin.dart';
part 'widgets/entry_actions.dart';
part 'widgets/entry_copy.dart';
part 'widgets/entry_hero.dart';

/// Uygulama giriş (landing) ekranı — oturumsuz kullanıcılar için ilk sayfa.
final class EntryView extends StatefulWidget {
  const EntryView({super.key});

  @override
  State<EntryView> createState() => _EntryViewState();
}

class _EntryViewState extends State<EntryView> with EntryViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Expanded(child: EntryHero()),
              const SizedBox(height: 20),
              const EntryCopy(),
              const SizedBox(height: 100),
              EntryActions(
                onGetStarted: onGetStarted,
                onAlreadyHaveAccount: onAlreadyHaveAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
