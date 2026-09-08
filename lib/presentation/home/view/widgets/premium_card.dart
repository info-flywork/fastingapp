part of '../home_view.dart';

/// Premium'a yükseltme kartı (premium olmayan kullanıcılar için).
final class PremiumCard extends StatelessWidget {
  const PremiumCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.workspace_premium_outlined),
        title: const Text('Go Premium'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
