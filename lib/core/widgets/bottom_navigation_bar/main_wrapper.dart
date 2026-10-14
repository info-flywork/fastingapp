import 'dart:async';

import 'package:fastingapp/core/app_update/app_update_gate.dart';
import 'package:fastingapp/core/legal/legal_consent_prompt.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/app_bottom_nav.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Shell route sarmalayıcı: bottom navigation ve aktif tab içeriği.
/// (Doküman 11)
final class MainWrapper extends StatefulWidget {
  const MainWrapper({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    // Oturum açık ve onboarding bitmiş: güncel yasal metin onayı.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(AppUpdateGate.check());
      unawaited(LegalConsentPrompt.maybeShow(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMochiWorldTab = navigationShell.currentIndex == 2;
    final isPlansTab = navigationShell.currentIndex == 3;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isPlansTab
            ? ColorName.colorWhite
            : isMochiWorldTab
            ? const Color(0xFFB8D9F0)
            : ColorName.colorProfileBack,
        // Scaffold bottomNavigationBar slot'u bazen 1px saçak bırakır;
        // nav'ı body Stack içinde çiziyoruz.
        body: Stack(
          children: [
            SafeArea(
              top: !isMochiWorldTab,
              bottom: false,
              child: navigationShell,
            ),
            if (!isMochiWorldTab)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNav(
                  currentIndex: navigationShell.currentIndex,
                  onTap: (index) => navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
