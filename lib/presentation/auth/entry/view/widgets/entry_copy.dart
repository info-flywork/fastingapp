part of '../entry_view.dart';

/// Başlık + alt metin.
final class EntryCopy extends StatelessWidget {
  const EntryCopy({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'auth.entry_title'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: FontFamily.sFProDisplay,
            fontWeight: FontWeight.w600,
            fontSize: 32,
            height: 40 / 32,
            letterSpacing: -0.5,
            color: ColorName.colorTitle,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'auth.entry_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FontFamily.sFProDisplay,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            height: 28 / 20,
            letterSpacing: -0.5,
            color: ColorName.colorSubtitle.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
