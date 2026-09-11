import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/welcome/bloc/welcome_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

part 'mixin/login_view_mixin.dart';
part 'widgets/login_actions.dart';
part 'widgets/login_copy.dart';
part 'widgets/login_hero.dart';

/// Login ekranı — Apple, Google, misafir.
final class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with LoginViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorLoginBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: LoginCopy(),
            ),
            const Expanded(child: LoginHero()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LoginActions(
                onApple: onApple,
                onGoogle: onGoogle,
                onGuest: onGuest,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _LoginLegalText(),
            ),
          ],
        ),
      ),
    );
  }
}
