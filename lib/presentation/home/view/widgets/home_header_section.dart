part of '../home_view.dart';

/// Home üst başlık bölümü (kullanıcı selamlama).
final class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Hi, ${user.name ?? 'there'}'),
      ),
    );
  }
}
