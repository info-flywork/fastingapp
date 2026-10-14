part of '../calories_camera_view.dart';

mixin CaloriesCameraViewMixin on State<CaloriesCameraView> {
  CameraController? cameraController;
  String? cameraError;
  bool isCapturing = false;

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          cameraError = 'calories_camera.no_camera'.tr();
        });
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        cameraController = controller;
        cameraError = null;
      });
    } on CameraException catch (e) {
      setState(() {
        cameraError = e.description ?? 'calories_camera.init_failed'.tr();
      });
    } on Object catch (_) {
      setState(() {
        cameraError = 'calories_camera.init_failed'.tr();
      });
    }
  }

  Future<void> onCapture() async {
    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized || isCapturing) {
      return;
    }

    if (!await AiConsent.ensure(context)) return;
    if (!mounted) return;

    setState(() => isCapturing = true);
    try {
      await HapticFeedback.mediumImpact();
      final shot = await controller.takePicture();
      if (!mounted) return;
      final saved = await context.pushNamed<bool>(
        RoutePaths.caloriesResult.name,
        extra: shot.path,
      );
      // Öğün kaydedildiyse kameraya değil takip ekranına dönülür.
      if ((saved ?? false) && mounted) {
        context.pop(true);
        return;
      }
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        cameraError = e.description ?? 'calories_camera.capture_failed'.tr();
      });
    } finally {
      if (mounted) setState(() => isCapturing = false);
    }
  }

  void disposeCamera() {
    unawaited(cameraController?.dispose());
    cameraController = null;
  }
}
