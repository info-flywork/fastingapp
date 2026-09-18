import 'package:fastingapp/core/widgets/bottom_navigation_bar/app_bottom_nav.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Shell route sarmalayıcı: bottom navigation ve aktif tab içeriği.
/// (Doküman 11)
final class MainWrapper extends StatelessWidget {
  const MainWrapper({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isPlansTab = navigationShell.currentIndex == 3;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
            isPlansTab ? ColorName.colorWhite : ColorName.colorProfileBack,
        body: SafeArea(
          bottom: false,
          child: navigationShell,
        ),
        extendBody: true,
        bottomNavigationBar: AppBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
