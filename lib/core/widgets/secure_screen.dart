import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/services/screen_protector_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
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

  const SecureScreen({
    super.key,
    required this.child,
    this.enabled = true,
    this.screenTitle,
    this.hideOnScreenRecording = true,
    this.protectInBackground = true,
    this.onScreenshotAttempted,
    this.tabIndex,
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
  Worker? _navWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.enabled) {
      _enableProtection();
      _setupIosListeners();

      if (widget.tabIndex != null && Get.isRegistered<NavigationController>()) {
        _navWorker = ever(Get.find<NavigationController>().currentIndex, (int index) {
          if (index == widget.tabIndex) {
            if (widget.enabled && _isRouteActive) {
              _enableProtection();
            }
          } else {
            _disableProtection();
          }
        });
      }
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
    ScreenProtectorService.enableProtection();
  }

  void _disableProtection() {
    _isRouteActive = false;
    ScreenProtectorService.disableProtection();
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
        Helpers.showCustomSnackBar(
          "⚠️ Screenshots are restricted on this screen to protect confidential data.",
          isError: true,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled || !widget.protectInBackground) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_isInBackground) {
        setState(() => _isInBackground = true);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isInBackground) {
        setState(() => _isInBackground = false);
      }
    }
  }

  // RouteAware: When another screen is pushed on top of this one
  @override
  void didPushNext() {
    // Temporarily disable secure mode so the newly pushed screen can take screenshots
    _disableProtection();
  }

  // RouteAware: When returning back to this screen from a pushed route
  @override
  void didPopNext() {
    // Re-enable secure mode for this screen
    if (widget.enabled) {
      _enableProtection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenProtectorService.routeObserver.unsubscribe(this);
    _navWorker?.dispose();
    _captureSubscription?.cancel();
    _screenshotSubscription?.cancel();

    if (widget.enabled) {
      _disableProtection();
    }
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
