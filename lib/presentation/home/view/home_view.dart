import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/data/model/user/user_progress.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'mixin/home_view_mixin.dart';
part 'widgets/home_loading_body.dart';
part 'widgets/home_loaded_body.dart';
part 'widgets/home_error_body.dart';
part 'widgets/home_header_section.dart';
part 'widgets/level_progress_card.dart';
part 'widgets/premium_card.dart';

/// Home ekranı. build() sadece iskeleti kurar; state'e göre body döndürür.
/// (Doküman 15.1)
final class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with HomeViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) showErrorSnackbar(state.message);
        },
        builder: (context, state) {
          return switch (state) {
            HomeInitial() || HomeLoading() => const HomeLoadingBody(),
            HomeLoaded(:final user, :final progress, :final isPremium) =>
              HomeLoadedBody(
                user: user,
                progress: progress,
                isPremium: isPremium,
                onPremiumTapped: onPremiumTapped,
              ),
            HomeError(:final message) => HomeErrorBody(
              message: message,
              onRetry: onRetry,
            ),
          };
        },
      ),
    );
  }
}
