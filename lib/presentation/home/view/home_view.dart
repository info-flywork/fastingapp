import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/app_bottom_nav.dart';
import 'package:fastingapp/core/widgets/weight_progress_bar.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/data/model/user/user_progress.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/chat/view/widgets/ai_chat_header_icon.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/home_view_mixin.dart';
part 'widgets/home_challenge_card.dart';
part 'widgets/home_error_body.dart';
part 'widgets/home_fasting_card.dart';
part 'widgets/home_loaded_body.dart';
part 'widgets/home_loading_body.dart';
part 'widgets/home_metric_cards.dart';
part 'widgets/home_metabolic_card.dart';
part 'widgets/home_meal_records_card.dart';
part 'widgets/home_hunger_tracker_card.dart';
part 'widgets/home_top_bar.dart';
part 'widgets/home_week_strip.dart';
part 'widgets/home_weight_card.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorProfileBack,
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
                  onChatTapped: onChatTapped,
                  onWaterTapped: onWaterTapped,
                  onStepsTapped: onStepsTapped,
                  onWeightTapped: onWeightTapped,
                  onWeightEditTapped: onWeightEditTapped,
                  onMealRecordsTapped: onMealRecordsTapped,
                  onHungerTrackerTapped: onHungerTrackerTapped,
                ),
              HomeError(:final message) => HomeErrorBody(
                message: message,
                onRetry: onRetry,
              ),
            };
          },
        ),
      ),
    );
  }
}
