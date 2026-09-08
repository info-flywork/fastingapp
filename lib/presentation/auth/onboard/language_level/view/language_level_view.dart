import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/bloc/language_level_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/bloc/language_level_event.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/bloc/language_level_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/language_level_view_mixin.dart';
part 'widgets/level_card.dart';

/// Onboarding seviye seçim ekranı.
final class LanguageLevelView extends StatefulWidget {
  const LanguageLevelView({super.key});

  @override
  State<LanguageLevelView> createState() => _LanguageLevelViewState();
}

class _LanguageLevelViewState extends State<LanguageLevelView>
    with LanguageLevelViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LanguageLevelBloc, LanguageLevelState>(
        listener: onStateChanged,
        builder: (context, state) {
          final selected =
              state is LanguageLevelInitial ? state.selectedLevel : null;
          return SafeArea(
            child: Column(
              children: [
                for (var level = 1; level <= 3; level++)
                  LevelCard(
                    level: level,
                    isSelected: selected == level,
                    onTap: () => context
                        .read<LanguageLevelBloc>()
                        .add(LanguageLevelSelected(level)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
