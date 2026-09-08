import 'package:flutter/material.dart';

/// Paylaşılan loading göstergesi.
final class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}

/// `withLoading` extension'ının gösterdiği modal loading dialog. (Doküman 9.6)
final class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 56,
        height: 56,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: AppLoading(),
          ),
        ),
      ),
    );
  }
}
