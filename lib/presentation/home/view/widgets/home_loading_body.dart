part of '../home_view.dart';

/// Home yükleniyor durumu gövdesi.
final class HomeLoadingBody extends StatelessWidget {
  const HomeLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}
