import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_bloc.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/splash_view_mixin.dart';
part 'widgets/splash_logo.dart';

/// Splash ekranı. Navigasyon [SplashNavigateTo] state'ine göre yapılır.
final class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SplashViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<SplashBloc, SplashState>(
        listener: onStateChanged,
        child: const Center(child: SplashLogo()),
      ),
    );
  }
}
