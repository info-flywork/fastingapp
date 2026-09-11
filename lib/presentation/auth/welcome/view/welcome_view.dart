import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/presentation/auth/welcome/bloc/welcome_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/welcome_view_mixin.dart';
part 'widgets/guest_login_button.dart';
part 'widgets/social_login_button.dart';

/// Karşılama ekranı.
final class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> with WelcomeViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SocialLoginButton(onTap: onGoogle),
              const SizedBox(height: 12),
              GuestLoginButton(onTap: onGuest),
            ],
          ),
        ),
      ),
    );
  }
}
