import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ScreenProtectorService {
  static const MethodChannel _channel =
      MethodChannel('com.moeb26.app/screen_protector');

  /// Global RouteObserver for tracking route transitions (pushes, pops)
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static int _activeProtectorCount = 0;
  static bool _isSecureActive = false;

  static int _activeWakeLockCount = 0;
  static bool _isWakeLockActive = false;

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

    if (Platform.isIOS) {
      try {
        ScreenProtector.addListener(() {
          _screenshotTakenController.add(null);
          debugPrint('📸 ScreenProtector library: screenshot detected');
        }, (isRecording) {
          _screenCapturedController.add(isRecording);
          debugPrint('🛡️ ScreenProtector library: screen capture changed: $isRecording');
        });
      } catch (e) {
        debugPrint('⚠️ ScreenProtector addListener error: $e');
      }
    }
  }

  /// Enables screenshot & screen recording protection (FLAG_SECURE on Android & iOS ScreenProtector)
  static Future<void> enableProtection() async {
    initialize();
    _activeProtectorCount++;

    if (!_isSecureActive && _activeProtectorCount > 0) {
      _isSecureActive = true;
      try {
        if (Platform.isAndroid) {
          await _channel.invokeMethod('enableSecure');
          debugPrint('🔒 ScreenProtector: Android native FLAG_SECURE ENABLED');
        }
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: Error enabling Android native protection: $e');
      }

      try {
        await ScreenProtector.preventScreenshotOn();
        debugPrint('🔒 ScreenProtector: preventScreenshotOn ENABLED (Android & iOS)');
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: preventScreenshotOn error: $e');
      }

      try {
        if (Platform.isIOS) {
          await ScreenProtector.protectDataLeakageWithBlur();
          debugPrint('🛡️ ScreenProtector: iOS app-switcher blur ENABLED');
        }
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: protectDataLeakage error: $e');
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
          debugPrint('🔓 ScreenProtector: Android native FLAG_SECURE DISABLED');
        }
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: Error disabling Android native protection: $e');
      }

      try {
        await ScreenProtector.preventScreenshotOff();
        debugPrint('🔓 ScreenProtector: preventScreenshotOff DISABLED');
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: preventScreenshotOff error: $e');
      }

      try {
        if (Platform.isIOS) {
          await ScreenProtector.protectDataLeakageOff();
          debugPrint('🛡️ ScreenProtector: iOS app-switcher blur DISABLED');
        }
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: protectDataLeakageOff error: $e');
      }
    }
  }

  /// Enables screen keep-awake (Prevents screen from turning off/sleeping)
  static Future<void> enableWakeLock() async {
    _activeWakeLockCount++;

    if (!_isWakeLockActive && _activeWakeLockCount > 0) {
      _isWakeLockActive = true;

      // 1. Flutter Wakelock Plus
      try {
        await WakelockPlus.enable();
        debugPrint('💡 ScreenProtector: WakelockPlus keep-awake ENABLED');
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: WakelockPlus enable error: $e');
      }

      // 2. Hardware Native Window Keep-Awake (FLAG_KEEP_SCREEN_ON on Android / isIdleTimerDisabled on iOS)
      try {
        await _channel.invokeMethod('enableWakeLock');
        debugPrint('💡 ScreenProtector: Native window keep-awake ENABLED (no sleep)');
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: Native wakelock enable error: $e');
      }
    }
  }

  /// Disables screen keep-awake (Restores normal screen sleeping)
  static Future<void> disableWakeLock() async {
    if (_activeWakeLockCount > 0) {
      _activeWakeLockCount--;
    }

    if (_isWakeLockActive && _activeWakeLockCount <= 0) {
      _isWakeLockActive = false;
      _activeWakeLockCount = 0;

      // 1. Flutter Wakelock Plus
      try {
        await WakelockPlus.disable();
        debugPrint('🌙 ScreenProtector: WakelockPlus keep-awake DISABLED');
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: WakelockPlus disable error: $e');
      }

      // 2. Hardware Native Window Keep-Awake
      try {
        await _channel.invokeMethod('disableWakeLock');
        debugPrint('🌙 ScreenProtector: Native window keep-awake DISABLED (sleep restored)');
      } catch (e) {
        debugPrint('⚠️ ScreenProtector: Native wakelock disable error: $e');
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

  /// Current state of wakelock
  static bool get isWakeLockActive => _isWakeLockActive;
}