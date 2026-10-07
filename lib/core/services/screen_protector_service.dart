import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScreenProtectorService {
  static const MethodChannel _channel =
      MethodChannel('com.moeb26.app/screen_protector');

  /// Global RouteObserver for tracking route transitions (pushes, pops)
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static int _activeProtectorCount = 0;
  static bool _isSecureActive = false;

  static final StreamController<bool> _screenCapturedController =
      StreamController<bool>.broadcast();
  static final StreamController<void> _screenshotTakenController =
      StreamController<void>.broadcast();

  /// Stream emitting boolean when iOS screen recording / mirroring changes
  static Stream<bool> get onScreenCapturedChanged =>
      _screenCapturedController.stream;

  /// Stream emitting event when user takes a screenshot on iOS
  static Stream<void> get onScreenshotTaken =>
      _screenshotTakenController.stream;

  static bool _isChannelInitialized = false;

  /// Initialize method call handler for iOS capture & screenshot events
  static void initialize() {
    if (_isChannelInitialized) return;
    _isChannelInitialized = true;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onScreenCapturedChanged':
          final bool isCaptured = call.arguments == true;
          _screenCapturedController.add(isCaptured);
          debugPrint('🛡️ ScreenProtector: iOS screen capture changed: $isCaptured');
          break;
        case 'onUserDidTakeScreenshot':
          _screenshotTakenController.add(null);
          debugPrint('📸 ScreenProtector: iOS screenshot detected');
          break;
        default:
          break;
      }
    });
  }

  /// Enables screenshot & screen recording protection (FLAG_SECURE on Android)
  static Future<void> enableProtection() async {
    initialize();
    _activeProtectorCount++;

    if (!_isSecureActive && _activeProtectorCount > 0) {
      _isSecureActive = true;
      try {
        if (Platform.isAndroid) {
          await _channel.invokeMethod('enableSecure');
          debugPrint('🔒 ScreenProtector: Android FLAG_SECURE ENABLED');
        }
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: Error enabling protection: $e');
      }
    }
  }

  /// Disables screenshot & screen recording protection
  static Future<void> disableProtection() async {
    initialize();
    if (_activeProtectorCount > 0) {
      _activeProtectorCount--;
    }

    if (_isSecureActive && _activeProtectorCount <= 0) {
      _isSecureActive = false;
      _activeProtectorCount = 0;
      try {
        if (Platform.isAndroid) {
          await _channel.invokeMethod('disableSecure');
          debugPrint('🔓 ScreenProtector: Android FLAG_SECURE DISABLED');
        }
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: Error disabling protection: $e');
      }
    }
  }

  /// Checks if iOS screen is currently being recorded or mirrored
  static Future<bool> isScreenCaptured() async {
    if (!Platform.isIOS) return false;
    try {
      final bool? isCaptured = await _channel.invokeMethod<bool>('isScreenCaptured');
      return isCaptured == true;
    } catch (_) {
      return false;
    }
  }

  /// Current state of protection
  static bool get isProtectionActive => _isSecureActive;
}
