import 'dart:async';

import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/domain/chat/ai_consent.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/calories_camera_view_mixin.dart';

/// Kalori hesapla — yemek fotoğrafı için kamera önizleme.
final class CaloriesCameraView extends StatefulWidget {
  const CaloriesCameraView({super.key});

  @override
  State<CaloriesCameraView> createState() => _CaloriesCameraViewState();
}

class _CaloriesCameraViewState extends State<CaloriesCameraView>
    with CaloriesCameraViewMixin {
  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ColorName.colorBlack,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _CameraPreviewLayer(controller: cameraController),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 16,
              child: _CircleBackButton(onTap: () => context.pop()),
            ),
            const Center(child: _ViewfinderFrame()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ShutterBar(
                bottomInset: bottom,
                onCapture: onCapture,
                isCapturing: isCapturing,
              ),
            ),
            if (cameraError != null)
              Positioned.fill(
                child: ColoredBox(
                  color: ColorName.colorBlack.withValues(alpha: 0.72),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        cameraError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ColorName.colorWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _CameraPreviewLayer extends StatelessWidget {
  const _CameraPreviewLayer({required this.controller});

  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const ColoredBox(
        color: ColorName.colorBlack,
        child: Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(ColorName.colorWhite),
          ),
        ),
      );
    }

    final preview = controller!.value.previewSize;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: preview?.height ?? 1,
        height: preview?.width ?? 1,
        child: CameraPreview(controller!),
      ),
    );
  }
}

final class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: ColorName.colorBlack.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Assets.icons.solarAltArrowUpLineDuotone.svg(
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                ColorName.colorTitle,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ortada 4 L köşe — ~48px, 4px beyaz stroke.
final class _ViewfinderFrame extends StatelessWidget {
  const _ViewfinderFrame();

  static const _frameSize = 280.0;
  static const _corner = 48.0;
  static const _stroke = 4.0;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: _frameSize,
      height: _frameSize,
      child: CustomPaint(
        painter: _ViewfinderPainter(cornerSize: _corner, strokeWidth: _stroke),
      ),
    );
  }
}

final class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({
    required this.cornerSize,
    required this.strokeWidth,
  });

  final double cornerSize;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ColorName.colorWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final c = cornerSize;

    canvas
      ..drawLine(Offset(0, c), Offset.zero, paint)
      ..drawLine(Offset.zero, Offset(c, 0), paint)
      ..drawLine(Offset(size.width - c, 0), Offset(size.width, 0), paint)
      ..drawLine(Offset(size.width, 0), Offset(size.width, c), paint)
      ..drawLine(Offset(0, size.height - c), Offset(0, size.height), paint)
      ..drawLine(Offset(0, size.height), Offset(c, size.height), paint)
      ..drawLine(
        Offset(size.width - c, size.height),
        Offset(size.width, size.height),
        paint,
      )
      ..drawLine(
        Offset(size.width, size.height - c),
        Offset(size.width, size.height),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.cornerSize != cornerSize ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

final class _ShutterBar extends StatelessWidget {
  const _ShutterBar({
    required this.bottomInset,
    required this.onCapture,
    required this.isCapturing,
  });

  final double bottomInset;
  final VoidCallback onCapture;
  final bool isCapturing;

  static const _barHeight = 132.0;
  static const _shutterSize = 78.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColorName.colorBlack,
      child: SizedBox(
        height: _barHeight + bottomInset,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Center(
            child: GestureDetector(
              onTap: isCapturing ? null : onCapture,
              behavior: HitTestBehavior.opaque,
              child: Opacity(
                opacity: isCapturing ? 0.55 : 1,
                child: AppImages.takePhoto.image(
                  width: _shutterSize,
                  height: _shutterSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
