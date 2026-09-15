part of '../profile_view.dart';

/// Bölüm başlığı + içerik.
final class ProfileSection extends StatelessWidget {
  const ProfileSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppTextStyles.profileSectionTitle),
        ),
        child,
      ],
    );
  }
}
