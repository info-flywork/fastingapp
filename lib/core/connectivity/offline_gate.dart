import 'dart:async';

import 'package:fastingapp/core/connectivity/connectivity_service.dart';
import 'package:fastingapp/presentation/no_internet/view/no_internet_view.dart';
import 'package:flutter/material.dart';

/// Uygulama kökünde (MaterialApp.builder): internet yokken tüm ekranların
/// üstüne internet yok sayfasını yumuşak geçişle koyar. Alttaki ekranlar ve
/// gezinme durumu korunur; bağlantı gelince sayfa kapanır.
final class OfflineGate extends StatelessWidget {
  const OfflineGate({required this.child, this.service, super.key});

  final Widget child;

  /// null → [ConnectivityService.instance].
  final ConnectivityService? service;

  @override
  Widget build(BuildContext context) {
    final connectivity = service ?? ConnectivityService.instance;
    return Stack(
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: connectivity.isOnline,
          builder: (context, online, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: online
                ? const SizedBox.shrink(key: ValueKey('online'))
                : ValueListenableBuilder<bool>(
                    key: const ValueKey('offline'),
                    valueListenable: connectivity.isChecking,
                    builder: (context, checking, _) => NoInternetView(
                      isChecking: checking,
                      onRetry: () => unawaited(connectivity.checkNow()),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
