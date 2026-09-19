import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../controllers/meet_greet_controller.dart';

class MeetGreetFullscreenView extends StatefulWidget {
  const MeetGreetFullscreenView({super.key});

  @override
  State<MeetGreetFullscreenView> createState() =>
      _MeetGreetFullscreenViewState();
}

class _MeetGreetFullscreenViewState extends State<MeetGreetFullscreenView> {
  final MeetGreetController controller = Get.find<MeetGreetController>();

  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    controller.enterFullscreen();
    controller.unlockOrientation();
    WakelockPlus.enable();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    WakelockPlus.disable();
    controller.exitFullscreen();
    controller.resetOrientation();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _showQuickEditDialog(BuildContext context) {
    final nameEditingController = TextEditingController(
      text: controller.passengerName.value,
    );
    final subtitleEditingController = TextEditingController(
      text: controller.subtitleText.value,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: const BorderSide(color: Color(0xFF364153)),
          ),
          title: Text(
            'Quick Edit Sign Board',
            style: GoogleFonts.inter(
              color: const Color(0xFFD5C4AB),
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEditingController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16.sp),
                decoration: InputDecoration(
                  labelText: 'Passenger / Guest Name',
                  labelStyle: GoogleFonts.inter(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF364153)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFD5C4AB)),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: subtitleEditingController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
                decoration: InputDecoration(
                  labelText: 'Flight / Note Subtitle',
                  labelStyle: GoogleFonts.inter(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF364153)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFD5C4AB)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            CustomButton(
              text: 'Update Name',
              onPressed: () {
                if (nameEditingController.text.trim().isNotEmpty) {
                  controller.passengerName.value = nameEditingController.text
                      .trim();
                }
                controller.subtitleText.value = subtitleEditingController.text
                    .trim();
                Navigator.pop(context);
              },
              width: null,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        controller.exitFullscreen();
        controller.resetOrientation();
      },
      child: Obx(() {
        final theme = controller.currentTheme;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: GestureDetector(
            onTap: _toggleControls,
            onDoubleTap: () => _showQuickEditDialog(context),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                // Main Sign Board Content
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 16.w : 24.w,
                      vertical: isLandscape ? 8.h : 20.h,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
                        Expanded(
                          child: Center(
                            child: _buildNameCard(
                              theme,
                              isLandscape: isLandscape,
                            ),
                          ),
                        ),
                        if (controller.subtitleText.value.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: isLandscape ? 4.h : 8.h),
                            child: Text(
                              controller.subtitleText.value.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: theme.subtitleColor,
                                fontSize: isLandscape ? 22.sp : 20.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5.w,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Top-Left Logo (Positioned Overlay)
                if (controller.showCompanyLogo.value &&
                    controller.customLogoPath.value != null)
                  Positioned(
                    top: isLandscape ? 12.h : 20.h,
                    left: isLandscape ? 16.w : 24.w,
                    child: SafeArea(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          File(controller.customLogoPath.value!),
                          width: isLandscape ? 100.h : 75.h,
                          height: isLandscape ? 100.h : 75.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                // --- FLOATING CONTROLS OVERLAY ---
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Stack(
                      children: [
                        // Top Bar Actions
                        Positioned(
                          top: 20.h,
                          right: 20.w,
                          child: SafeArea(
                            child: Row(
                              children: [
                                _buildControlButton(
                                  icon: Icons.edit_note_rounded,
                                  tooltip: 'Edit Name',
                                  onTap: () => _showQuickEditDialog(context),
                                  theme: theme,
                                ),
                                SizedBox(width: 10.w),
                                _buildControlButton(
                                  icon: Icons.close_rounded,
                                  tooltip: 'Exit Full Screen',
                                  onTap: () {
                                    controller.exitFullscreen();
                                    controller.resetOrientation();
                                    Get.back();
                                  },
                                  theme: theme,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Hint Toast
                        Positioned(
                          bottom: 25.h,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(30.r),
                                border: Border.all(
                                  color: theme.borderColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app_outlined,
                                    color: theme.headerColor,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Tap screen to toggle controls  |  Double tap to edit name',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNameCard(MeetGreetThemeData theme, {required bool isLandscape}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: isLandscape ? 2.h : 10.h),
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 8.w : 16.w,
        vertical: isLandscape ? 4.h : 16.h,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            controller.passengerName.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: theme.nameColor,
              fontSize:
                  ((isLandscape ? 200 : 70) * controller.fontSizeScale.value)
                      .sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.w,
              shadows: [
                Shadow(
                  color: theme.borderColor.withValues(alpha: 0.4),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required MeetGreetThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: theme.borderColor, width: 1.5),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22.sp),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}
