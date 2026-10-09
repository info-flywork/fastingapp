import 'package:flutter/material.dart';

/// Tek animasyonlu shimmer sarmalayıcı — çocuklardaki gri kemikler parlar.
final class AppShimmer extends StatefulWidget {
  const AppShimmer({
    required this.child,
    this.baseColor = const Color(0xFFE6E6E8),
    this.highlightColor = const Color(0xFFF4F4F5),
    super.key,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
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
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.8 + 3.6 * t, 0),
              end: Alignment(-0.2 + 3.6 * t, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer iskelet kutusu ([AppShimmer] içinde kullan).
final class AppShimmerBone extends StatelessWidget {
  const AppShimmerBone({
    required this.height,
    this.width,
    this.borderRadius,
    this.margin,
    super.key,
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final bone = Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
    );
    if (margin == null) return bone;
    return Padding(padding: margin!, child: bone);
  }
}
