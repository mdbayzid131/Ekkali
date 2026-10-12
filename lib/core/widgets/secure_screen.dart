import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/services/screen_protector_service.dart';
import 'package:moeb_26/modules/bottom_nab_bar/controllers/bottom_nabbar_controller.dart';

/// A reusable security wrapper that protects sensitive screens from:
/// - Android: Screenshots and Screen Recording via native `FLAG_SECURE`
/// - iOS: Screen Recording detection, Screenshot detection, and App Switcher blur
class SecureScreen extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final String? screenTitle;
  final bool hideOnScreenRecording;
  final bool protectInBackground;
  final VoidCallback? onScreenshotAttempted;
  final int? tabIndex;
  final bool keepScreenOn;

  const SecureScreen({
    super.key,
    required this.child,
    this.enabled = true,
    this.screenTitle,
    this.hideOnScreenRecording = true,
    this.protectInBackground = true,
    this.onScreenshotAttempted,
    this.tabIndex,
    this.keepScreenOn = false,
  });

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen>
    with WidgetsBindingObserver, RouteAware {
  bool _isScreenRecordingActive = false;
  bool _isInBackground = false;
  StreamSubscription<bool>? _captureSubscription;
  StreamSubscription<void>? _screenshotSubscription;
  bool _isRouteActive = true;
  bool _hasActiveProtection = false;
  bool _hasActiveWakeLock = false;
  bool _wasWakeLockPausedForLifecycle = false;
  Worker? _navWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final bool isTabMatching = widget.tabIndex == null ||
        (!Get.isRegistered<NavigationController>() ||
            Get.find<NavigationController>().currentIndex.value == widget.tabIndex);

    if (isTabMatching) {
      if (widget.enabled) {
        _enableProtection();
      }
      if (widget.keepScreenOn) {
        _enableWakeLock();
      }
    }

    if (widget.enabled) {
      _setupIosListeners();
    }

    if (widget.tabIndex != null && Get.isRegistered<NavigationController>()) {
      _navWorker = ever(Get.find<NavigationController>().currentIndex, (int index) {
        if (index == widget.tabIndex) {
          if (_isRouteActive) {
            if (widget.enabled) _enableProtection();
            if (widget.keepScreenOn) _enableWakeLock();
          }
        } else {
          _disableProtection();
          _disableWakeLock();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      ScreenProtectorService.routeObserver.subscribe(this, modalRoute);
    }
  }

  void _enableProtection() {
    _isRouteActive = true;
    if (_hasActiveProtection || !widget.enabled) return;
    _hasActiveProtection = true;
    ScreenProtectorService.enableProtection();
  }

  void _disableProtection() {
    if (!_hasActiveProtection) return;
    _hasActiveProtection = false;
    ScreenProtectorService.disableProtection();
  }

  void _enableWakeLock() {
    if (_hasActiveWakeLock || !widget.keepScreenOn) return;
    _hasActiveWakeLock = true;
    ScreenProtectorService.enableWakeLock();
  }

  void _disableWakeLock() {
    if (!_hasActiveWakeLock) return;
    _hasActiveWakeLock = false;
    ScreenProtectorService.disableWakeLock();
  }

  void _setupIosListeners() {
    if (!Platform.isIOS) return;

    // Check initial recording state on iOS
    ScreenProtectorService.isScreenCaptured().then((captured) {
      if (mounted) {
        setState(() => _isScreenRecordingActive = captured);
      }
    });

    // Listen to screen recording changes
    _captureSubscription =
        ScreenProtectorService.onScreenCapturedChanged.listen((isCaptured) {
      if (mounted) {
        setState(() => _isScreenRecordingActive = isCaptured);
      }
    });

    // Listen to screenshot event on iOS
    _screenshotSubscription =
        ScreenProtectorService.onScreenshotTaken.listen((_) {
      if (mounted && _isRouteActive && widget.enabled) {
        widget.onScreenshotAttempted?.call();
        _hasPendingScreenshotWarning = true;
        _showScreenshotWarningDialog();
      }
    });
  }

  bool _isWarningDialogShowing = false;
  bool _hasPendingScreenshotWarning = false;

  void _showScreenshotWarningDialog() {
    if (!mounted || _isWarningDialogShowing || !_isRouteActive) return;
    _isWarningDialogShowing = true;
    _hasPendingScreenshotWarning = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF141416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: const BorderSide(color: Color(0xFF2E2E38), width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.no_photography_outlined,
                    color: const Color(0xFFE53935),
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Screenshots Not Allowed",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  "The app does not allow screenshots on this screen to protect confidential job offer details.",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9E9EA8),
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: Text(
                      "Understood",
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isWarningDialogShowing = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (widget.enabled && widget.protectInBackground && !_isInBackground) {
        setState(() => _isInBackground = true);
      }
      if (_hasActiveWakeLock) {
        _disableWakeLock();
        _wasWakeLockPausedForLifecycle = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isInBackground) {
        setState(() => _isInBackground = false);
      }
      if (_hasPendingScreenshotWarning) {
        Future.delayed(const Duration(milliseconds: 250), () {
          _showScreenshotWarningDialog();
        });
      }
      if (_wasWakeLockPausedForLifecycle) {
        _wasWakeLockPausedForLifecycle = false;
        final bool isTabMatching = widget.tabIndex == null ||
            (!Get.isRegistered<NavigationController>() ||
                Get.find<NavigationController>().currentIndex.value == widget.tabIndex);
        if (_isRouteActive && isTabMatching && widget.keepScreenOn) {
          _enableWakeLock();
        }
      }
    }
  }

  // RouteAware: When another screen is pushed on top of this one
  @override
  void didPushNext() {
    // Temporarily disable secure mode & wakelock so pushed screen can function normally
    _isRouteActive = false;
    _disableProtection();
    // Keep wakelock active so opening dialogs/bottom sheets does not cause screen to sleep
  }

  // RouteAware: When returning back to this screen from a pushed route
  @override
  void didPopNext() {
    // Re-enable secure mode & wakelock for this screen
    _isRouteActive = true;
    final bool isTabMatching = widget.tabIndex == null ||
        (!Get.isRegistered<NavigationController>() ||
            Get.find<NavigationController>().currentIndex.value == widget.tabIndex);
    if (isTabMatching) {
      if (widget.enabled) {
        _enableProtection();
      }
      if (widget.keepScreenOn) {
        _enableWakeLock();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenProtectorService.routeObserver.unsubscribe(this);
    _navWorker?.dispose();
    _captureSubscription?.cancel();
    _screenshotSubscription?.cancel();

    _disableWakeLock();
    _disableProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    // 1. If iOS Screen Recording is active
    if (widget.hideOnScreenRecording && _isScreenRecordingActive) {
      return _buildPrivacyShield(
        icon: Icons.videocam_off_rounded,
        title: "Screen Recording Blocked",
        message:
            "This screen contains confidential job offers and cannot be recorded.",
      );
    }

    // 2. If App is in background / task switcher (protect from recents thumbnail snapshot)
    if (widget.protectInBackground && _isInBackground) {
      return Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primaryColor,
                      size: 40.sp,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Protected Screen",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }

  Widget _buildPrivacyShield({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF271C10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 34.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
