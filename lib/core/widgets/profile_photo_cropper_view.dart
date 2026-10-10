import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';

/// Full-screen high-end interactive profile picture cropper
class ProfilePhotoCropperView extends StatefulWidget {
  final File imageFile;
  final String title;
  final String subtitle;

  const ProfilePhotoCropperView({
    super.key,
    required this.imageFile,
    this.title = 'Adjust Profile Picture',
    this.subtitle = 'Scale & position your face within the circle',
  });

  @override
  State<ProfilePhotoCropperView> createState() =>
      _ProfilePhotoCropperViewState();
}

class _ProfilePhotoCropperViewState extends State<ProfilePhotoCropperView> {
  final TransformationController _transformController =
      TransformationController();

  int _rotationQuarterTurns = 0; // 0, 1, 2, 3 (each is 90 degrees)
  bool _isLoading = false;
  bool _isImageLoaded = false;
  int _rawImageWidth = 0;
  int _rawImageHeight = 0;
  Uint8List? _imageBytes;
  Size _viewportSize = Size.zero;
  double _cropDiameter = 0.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _rawImageWidth = decoded.width;
          _rawImageHeight = decoded.height;
          _isImageLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading image for cropping: $e");
      Helpers.showCustomSnackBar("Could not load image", isError: true);
      Get.back();
    }
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _transformController.value = Matrix4.identity();
    });
  }

  void _resetTransform() {
    setState(() {
      _rotationQuarterTurns = 0;
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _cropAndSave(double cropDiameter, Size viewportSize) async {
    if (_imageBytes == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Determine effective image dimensions considering rotation
      final bool isSideways =
          _rotationQuarterTurns == 1 || _rotationQuarterTurns == 3;
      final double effectiveImageWidth =
          (isSideways ? _rawImageHeight : _rawImageWidth).toDouble();
      final double effectiveImageHeight =
          (isSideways ? _rawImageWidth : _rawImageHeight).toDouble();

      if (effectiveImageWidth <= 0 ||
          effectiveImageHeight <= 0 ||
          cropDiameter <= 0) {
        return;
      }

      // Viewport center
      final double vxCenter = viewportSize.width / 2;
      final double vyCenter = viewportSize.height / 2;

      // Crop window in viewport coordinates
      final double cropLeft = vxCenter - cropDiameter / 2;
      final double cropTop = vyCenter - cropDiameter / 2;
      final double cropRight = vxCenter + cropDiameter / 2;
      final double cropBottom = vyCenter + cropDiameter / 2;

      // Invert current transformation matrix
      final Matrix4 inverted = Matrix4.inverted(_transformController.value);

      // Child display dimensions
      // The child is centered in the viewport with contain/cover fit
      final double baseScale = math.max(
        cropDiameter / effectiveImageWidth,
        cropDiameter / effectiveImageHeight,
      );
      final double displayWidth = effectiveImageWidth * baseScale;
      final double displayHeight = effectiveImageHeight * baseScale;

      final double childOffsetX = (viewportSize.width - displayWidth) / 2;
      final double childOffsetY = (viewportSize.height - displayHeight) / 2;

      // Map crop rectangle from viewport space to child space
      final Offset p1InViewport = Offset(cropLeft, cropTop);
      final Offset p2InViewport = Offset(cropRight, cropBottom);

      final Offset p1InChild = MatrixUtils.transformPoint(
        inverted,
        p1InViewport,
      );
      final Offset p2InChild = MatrixUtils.transformPoint(
        inverted,
        p2InViewport,
      );

      // Relative to child content
      final double relX1 = p1InChild.dx - childOffsetX;
      final double relY1 = p1InChild.dy - childOffsetY;
      final double relX2 = p2InChild.dx - childOffsetX;
      final double relY2 = p2InChild.dy - childOffsetY;

      // Map to original pixels
      final double px1 = (relX1 / displayWidth) * effectiveImageWidth;
      final double py1 = (relY1 / displayHeight) * effectiveImageHeight;
      final double px2 = (relX2 / displayWidth) * effectiveImageWidth;
      final double py2 = (relY2 / displayHeight) * effectiveImageHeight;

      final double pxMin = math.min(px1, px2);
      final double pyMin = math.min(py1, py2);
      final double pxMax = math.max(px1, px2);
      final double pyMax = math.max(py1, py2);

      // Background image cropping using compute
      final croppedFile = await compute(_performCropTask, {
        'bytes': _imageBytes!,
        'rotation': _rotationQuarterTurns * 90,
        'cropX': pxMin,
        'cropY': pyMin,
        'cropW': pxMax - pxMin,
        'cropH': pyMax - pyMin,
        'outSize': 700,
      });

      if (croppedFile != null && mounted) {
        Get.back(result: File(croppedFile));
      } else {
        Helpers.showCustomSnackBar("Failed to crop photo", isError: true);
      }
    } catch (e) {
      debugPrint("Crop error: $e");
      Helpers.showCustomSnackBar("Failed to crop photo", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static Future<String?> _performCropTask(Map<String, dynamic> params) async {
    try {
      final Uint8List bytes = params['bytes'] as Uint8List;
      final int rotation = params['rotation'] as int;
      final double cropX = (params['cropX'] as num).toDouble();
      final double cropY = (params['cropY'] as num).toDouble();
      final double cropW = (params['cropW'] as num).toDouble();
      final double cropH = (params['cropH'] as num).toDouble();
      final int outSize = params['outSize'] as int;

      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Bake orientation or rotate if user rotated
      image = img.bakeOrientation(image);
      if (rotation != 0) {
        image = img.copyRotate(image, angle: rotation);
      }

      final int ix = cropX.clamp(0, image.width - 1).toInt();
      final int iy = cropY.clamp(0, image.height - 1).toInt();
      final int iw = cropW.clamp(1, image.width - ix).toInt();
      final int ih = cropH.clamp(1, image.height - iy).toInt();

      final img.Image cropped = img.copyCrop(
        image,
        x: ix,
        y: iy,
        width: iw,
        height: ih,
      );

      final img.Image resized = img.copyResize(
        cropped,
        width: outSize,
        height: outSize,
        interpolation: img.Interpolation.cubic,
      );

      final List<int> jpegBytes = img.encodeJpg(resized, quality: 88);

      final tempDir = Directory.systemTemp;
      final filePath =
          '${tempDir.path}/cropped_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(jpegBytes);
      return file.path;
    } catch (e) {
      debugPrint("Error in _performCropTask: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildHeader(context),

            // Instruction Banner
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFFFEDB9B),
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Middle: Interactive Crop Viewport
            Expanded(
              child: _isImageLoaded && _imageBytes != null
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final double diameter = math.min(
                          constraints.maxWidth * 0.78,
                          constraints.maxHeight * 0.65,
                        );
                        _viewportSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        _cropDiameter = diameter;

                        final bool isSideways = _rotationQuarterTurns == 1 ||
                            _rotationQuarterTurns == 3;
                        final double effW = (isSideways
                                ? _rawImageHeight
                                : _rawImageWidth)
                            .toDouble();
                        final double effH = (isSideways
                                ? _rawImageWidth
                                : _rawImageHeight)
                            .toDouble();

                        final double baseScale = math.max(
                          diameter / effW,
                          diameter / effH,
                        );
                        final double displayW = effW * baseScale;
                        final double displayH = effH * baseScale;

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Interactive Pinch & Pan Viewer
                            InteractiveViewer(
                              transformationController: _transformController,
                              minScale: 0.8,
                              maxScale: 4.5,
                              boundaryMargin: EdgeInsets.all(diameter * 0.8),
                              child: Center(
                                child: SizedBox(
                                  width: displayW,
                                  height: displayH,
                                  child: RotatedBox(
                                    quarterTurns: _rotationQuarterTurns,
                                    child: Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Overlay: Dark vignette + Gold Circular Cutout + Grid
                            IgnorePointer(
                              child: CustomPaint(
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                                painter: _CropCircleOverlayPainter(
                                  diameter: diameter,
                                ),
                              ),
                            ),

                            // Rotate & Reset Floating Tools
                            Positioned(
                              bottom: 16.h,
                              left: 20.w,
                              right: 20.w,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildToolButton(
                                    icon: Icons.refresh_rounded,
                                    label: "Reset",
                                    onTap: _resetTransform,
                                  ),
                                  _buildToolButton(
                                    icon: Icons.rotate_right_rounded,
                                    label: "Rotate 90°",
                                    onTap: _rotateClockwise,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFEDB9B),
                      ),
                    ),
            ),

            // Bottom Actions Bar
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: "Cancel",
          ),
          Text(
            widget.title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 48.w), // Balance close button
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C20).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: const Color(0xFF33333E)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFEDB9B), size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F12),
        border: Border(top: BorderSide(color: Color(0xFF22222A), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3A3A44)),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: "Crop & Use Photo",
              loading: _isLoading,
              icon: Icon(
                Icons.check_rounded,
                color: Colors.black,
                size: 18.sp,
              ),
              onPressed: () {
                if (_viewportSize != Size.zero && _cropDiameter > 0) {
                  _cropAndSave(_cropDiameter, _viewportSize);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for circular crop overlay with darkened outer area and gold ring
class _CropCircleOverlayPainter extends CustomPainter {
  final double diameter;

  _CropCircleOverlayPainter({required this.diameter});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = diameter / 2;

    // 1. Dark mask outside circle
    final fullRect = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final maskPath = Path.combine(
      PathOperation.difference,
      fullRect,
      circlePath,
    );

    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawPath(maskPath, maskPaint);

    // 2. Gold circular border
    final borderPaint = Paint()
      ..color = const Color(0xFFFEDB9B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, borderPaint);

    // 3. Subtle grid lines inside circle (Rule of thirds)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final oneThird = diameter / 3;
    final leftX = center.dx - radius + oneThird;
    final rightX = center.dx - radius + (oneThird * 2);
    final topY = center.dy - radius + oneThird;
    final bottomY = center.dy - radius + (oneThird * 2);

    canvas.save();
    canvas.clipPath(circlePath);

    canvas.drawLine(
      Offset(leftX, center.dy - radius),
      Offset(leftX, center.dy + radius),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rightX, center.dy - radius),
      Offset(rightX, center.dy + radius),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, topY),
      Offset(center.dx + radius, topY),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, bottomY),
      Offset(center.dx + radius, bottomY),
      gridPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CropCircleOverlayPainter oldDelegate) {
    return oldDelegate.diameter != diameter;
  }
}
