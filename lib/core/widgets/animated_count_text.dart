import 'package:flutter/material.dart';

/// Tam sayıyı eski değerden yenisine doğru sayarak yazar.
/// İlk değer olduğu gibi gelir; sonraki değişimler akar.
final class AnimatedCountText extends StatefulWidget {
  const AnimatedCountText({
    required this.value,
    required this.style,
    this.format,
    this.duration = const Duration(milliseconds: 480),
    super.key,
  });

  final int value;
  final TextStyle style;
  final String Function(int value)? format;
  final Duration duration;

  @override
  State<AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<AnimatedCountText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _from;
  late int _to;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _to = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1;
  }

  @override
  void didUpdateWidget(AnimatedCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.value == widget.value) return;
    _from = _displayed;
    _to = widget.value;
    _controller.forward(from: 0);
  }

  int get _displayed {
    final t = Curves.easeOutCubic.transform(_controller.value);
    return (_from + (_to - _from) * t).round();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final n = _displayed;
        return Text(widget.format?.call(n) ?? '$n', style: widget.style);
      },
    );
  }
}
