import 'package:get/get.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;

enum SnackBarType { success, error, info, warning, secondary }

/// ===================== HELPERS =====================
/// Common utility functions used across the app.
class Helpers {
  Helpers._();

  // ──────────────────── TIME FORMATTING ────────────────────

  /// Format seconds to "mm:ss" (e.g., 125 → "02:05")
  static String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  /// Format DateTime to "time ago" string (e.g., "5m ago")
  static String timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  /// Format seconds to "HH:mm:ss" (e.g., 3661 → "01:01:01")
  static String formatDuration(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final mins = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }

  /// Format duration input string to "X h" (e.g. "7", "7 hours", "7h", "7 hrs" → "7 h")
  static String formatDurationToH(String? duration) {
    if (duration == null || duration.trim().isEmpty) return '';
    final trimmed = duration.trim();
    final regExp = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(?:h|hr|hrs|hour|hours)?$',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    if (match != null) {
      return '${match.group(1)}h';
    }
    return trimmed;
  }

  /// Format dropoff location string, ensuring By The Hour shows "By the hour (X h)"
  static String formatDropoffDisplay({
    String? jobType,
    String? dropoffLocation,
    String? duration,
  }) {
    final isByTheHour =
        (jobType?.toUpperCase() == 'BY THE HOUR') ||
        (dropoffLocation != null &&
            dropoffLocation.toLowerCase().contains('by the hour'));

    if (isByTheHour) {
      String? d = duration;
      if (d == null || d.trim().isEmpty) {
        if (dropoffLocation != null) {
          final match = RegExp(
            r'by the hour\s*\(([^)]+)\)',
            caseSensitive: false,
          ).firstMatch(dropoffLocation);
          if (match != null) {
            d = match.group(1);
          }
        }
      }
      final formattedD = formatDurationToH(d);
      if (formattedD.isNotEmpty) {
        return 'By the hour ($formattedD)';
      }
      return 'By the hour';
    }

    if (dropoffLocation == null || dropoffLocation.trim().isEmpty) {
      return 'As Directed';
    }
    return dropoffLocation;
  }

  // ──────────────────── LOGGING ────────────────────

  /// General debug log (only in debug mode)
  static void debug(String message) {
    if (!kDebugMode) return;
    debugPrint('');
    debugPrint('🔍🔍🔍 DEBUG: $message');
    debugPrint('');
  }

  /// Info-level log
  static void info(String message) {
    if (!kDebugMode) return;
    debugPrint('');
    debugPrint('ℹ️ℹ️ℹ️ℹ INFO: $message');
    debugPrint('');
  }

  /// Warning-level log
  static void warning(String message) {
    if (!kDebugMode) return;
    debugPrint('');
    debugPrint('⚠️⚠️⚠️ WARNING: $message');
    debugPrint('');
  }

  /// Error-level log
  static void error(String message) {
    if (!kDebugMode) return;
    debugPrint('');
    debugPrint('❌❌❌❌ ERROR: $message');
    debugPrint('');
  }

  /// Backward compatible showDebugLog
  static void showDebugLog(String message) {
    debug(message);
  }

  // ──────────────────── LOADING DIALOG ────────────────────

  /// Show a centered loading spinner dialog
  static void showLoadingDialog({String? message}) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                SizedBox(height: 16.h),
                Material(
                  color: Colors.transparent,
                  child: Text(
                    message,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }

  /// Dismiss loading dialog if open
  static void hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // ──────────────────── SNACKBAR (DUAL MODE) ────────────────────

  /// Show a snackbar. Supports backward-compatible signatures for moeb_26.
  /// [useGetxSnackbar] = true (default) → uses Get.snackbar with type-specific colors.
  /// [useGetxSnackbar] = false → uses the premium blurred iPhone-style snackbar.
  static void showCustomSnackBar(
    String? message, {
    String? title,
    bool isError = true,
    bool getXSnackBar = true, // Backward compatible
    Duration duration = const Duration(seconds: 3),
    bool useGetxSnackbar = true,
    SnackBarType? type,
  }) {
    if (message == null || message.isEmpty) return;

    // Map parameters to new style
    final SnackBarType resolvedType =
        type ?? (isError ? SnackBarType.error : SnackBarType.success);
    final bool resolvedUseGetx = useGetxSnackbar && getXSnackBar;

    final Map<String, dynamic> config = _getSnackBarConfig(resolvedType);

    if (resolvedUseGetx) {
      // ── GetX Snackbar (default) ──────────────────────────────
      Get.snackbar(
        title ?? config['defaultTitle'] as String,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: (config['bg'] as Color).withValues(alpha: 0.92),
        colorText: Colors.white,
        icon: Icon(
          config['icon'] as IconData,
          color: Colors.white,
          size: 26.sp,
        ),
        duration: duration,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
        animationDuration: const Duration(milliseconds: 450),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        borderRadius: 14.r,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        titleText: Text(
          title ?? config['defaultTitle'] as String,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        messageText: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );
    } else {
      // ── Custom Blur / Glassmorphism Snackbar ─────────────────
      Get.rawSnackbar(
        messageText: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 64.h,
              decoration: BoxDecoration(
                color: (config['bg'] as Color).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Left Icon Area
                  Container(
                    width: 56.w,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: (config['iconBg'] as Color).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        bottomLeft: Radius.circular(16.r),
                      ),
                    ),
                    child: Icon(
                      config['icon'],
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Text Content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? config['defaultTitle'],
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close Button
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        duration: duration,
        isDismissible: true,
        animationDuration: const Duration(milliseconds: 500),
        snackStyle: SnackStyle.FLOATING,
      );
    }
  }

  static Map<String, dynamic> _getSnackBarConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return {
          'bg': const Color(0xFF10B981),
          'iconBg': const Color(0xFF059669),
          'icon': Icons.check_rounded,
          'defaultTitle': 'Success',
        };
      case SnackBarType.error:
        return {
          'bg': const Color(0xFFEF4444),
          'iconBg': const Color(0xFFDC2626),
          'icon': Icons.block_rounded,
          'defaultTitle': 'Error',
        };
      case SnackBarType.warning:
        return {
          'bg': const Color(0xFFF59E0B),
          'iconBg': const Color(0xFFD97706),
          'icon': Icons.warning_rounded,
          'defaultTitle': 'Warning',
        };
      case SnackBarType.secondary:
        return {
          'bg': const Color(0xFF3B82F6),
          'iconBg': const Color(0xFF2563EB),
          'icon': Icons.notifications_none_rounded,
          'defaultTitle': 'Secondary',
        };
      case SnackBarType.info:
        return {
          'bg': const Color(0xFF9CA3AF),
          'iconBg': const Color(0xFF6B7280),
          'icon': Icons.info_outline_rounded,
          'defaultTitle': 'Info',
        };
    }
  }

  /// Shortcut for Success
  static void showSuccess(String message, {String? title}) {
    showCustomSnackBar(message, title: title, type: SnackBarType.success);
  }

  /// Shortcut for Error
  static void showError(String message, {String? title}) {
    showCustomSnackBar(message, title: title, type: SnackBarType.error);
  }

  /// Shortcut for Warning
  static void showWarning(String message, {String? title}) {
    showCustomSnackBar(message, title: title, type: SnackBarType.warning);
  }

  // ──────────────────── KEYBOARD ────────────────────

  /// Dismiss keyboard
  static void hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // ──────────────────── DEBOUNCE ────────────────────

  static final Map<String, bool> _debounceTimers = {};

  /// Debounce a function call (useful for search inputs)
  static void debounce(
    String tag,
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    if (GetUtils.isNull(tag)) return;

    // If already waiting, skip
    if (_debounceTimers[tag] == true) return;

    _debounceTimers[tag] = true;
    Future.delayed(duration, () {
      _debounceTimers.remove(tag);
      callback();
    });
  }

  /// Compress image file by resizing it to a maximum width of 1024 pixels.
  /// If the file is not an image (e.g. PDF), it returns the original file.
  static Future<File> compressImage(File file) async {
    final path = file.path.toLowerCase();
    if (path.endsWith('.pdf')) {
      return file;
    }
    try {
      final bytes = await file.readAsBytes();

      // Decode using pure Dart 'image' package
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded != null) {
        // Resize if width is larger than 1024 pixels
        img.Image resized = decoded;
        if (decoded.width > 1024) {
          resized = img.copyResize(decoded, width: 1024);
        }

        // Encode as JPEG with 70% quality (extremely high compression with good visual quality)
        final jpegBytes = img.encodeJpg(resized, quality: 70);

        final tempDir = Directory.systemTemp;

        // Extract original file name supporting both / and \ separators
        final originalFileName = file.path.split('/').last.split('\\').last;
        final baseName = originalFileName.contains('.')
            ? originalFileName.substring(0, originalFileName.lastIndexOf('.'))
            : originalFileName;

        // Create a unique subdirectory to prevent name collisions while keeping the filename clean
        final sessionDir = Directory(
          '${tempDir.path}/compressed_${DateTime.now().microsecondsSinceEpoch}',
        );
        await sessionDir.create(recursive: true);

        final tempPath = '${sessionDir.path}/$baseName.jpg';
        final compressedFile = File(tempPath);
        await compressedFile.writeAsBytes(jpegBytes);

        Helpers.debug(
          'Compressed image: ${file.path} (${bytes.length} bytes) -> $tempPath (${jpegBytes.length} bytes)',
        );
        return compressedFile;
      }
    } catch (e) {
      Helpers.error('Error compressing image: $e');
    }
    return file;
  }
}
