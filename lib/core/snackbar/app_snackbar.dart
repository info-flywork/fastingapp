import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Overlay tabanlı modern snackbar. Feature katmanında
/// `ScaffoldMessenger` doğrudan kullanılmaz. (Doküman 9.4)
final class AppSnackbar {
  const AppSnackbar._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  /// Kaydetme / yükleme hatası: sunucunun yerelleştirilmiş mesajı, değilse
  /// genel "başarısız".
  static void showError(BuildContext context, Object error) => show(
    context: context,
    text: error is NetworkException ? error.message : 'common.failed'.tr(),
    type: SnackBarType.failure,
  );

  static void show({
    required BuildContext context,
    required String text,
    required SnackBarType type,
    SnackBarPosition position = SnackBarPosition.top,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _removeEntry();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _SnackbarHost(
        text: text,
        type: type,
        position: position,
        duration: duration,
        onDismissed: () {
          if (_entry == entry) _removeEntry();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);

    // Animasyon reverse + güvenlik ağı.
    _timer = Timer(duration + const Duration(milliseconds: 400), () {
      if (_entry == entry) _removeEntry();
    });
  }

  static void _removeEntry() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

final class _SnackbarHost extends StatefulWidget {
  const _SnackbarHost({
    required this.text,
    required this.type,
    required this.position,
    required this.duration,
    required this.onDismissed,
  });

  final String text;
  final SnackBarType type;
  final SnackBarPosition position;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_SnackbarHost> createState() => _SnackbarHostState();
}

class _SnackbarHostState extends State<_SnackbarHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.position == SnackBarPosition.top
        ? const Offset(0, -0.4)
        : const Offset(0, 0.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.forward());
    _autoClose = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    _autoClose?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isTop = widget.position == SnackBarPosition.top;

    return Positioned(
      top: isTop ? media.padding.top + 12 : null,
      bottom: isTop ? null : media.padding.bottom + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _close,
                onVerticalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (isTop && v < -200) unawaited(_close());
                  if (!isTop && v > 200) unawaited(_close());
                },
                child: _SnackbarCard(text: widget.text, type: widget.type),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _SnackbarCard extends StatelessWidget {
  const _SnackbarCard({required this.text, required this.type});

  final String text;
  final SnackBarType type;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: ColorName.colorBlack.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: ColorName.colorBlack.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: type.color.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(type.icon, size: 20, color: type.color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: FontFamily.sFProDisplay,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 20 / 14,
                    letterSpacing: -0.2,
                    color: ColorName.colorTitle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
