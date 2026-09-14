import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/auth_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';

class OtpController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final pinController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  var isLoading = false.obs;
  var remainingSeconds = 90.obs;
  var canResend = false.obs;
  var otpError = ''.obs;
  Timer? _timer;

  String email = '';
  bool isRegister = false;

  @override
  void onInit() {
    super.onInit();
    email = Get.arguments?['email'] ?? '';
    isRegister = Get.arguments?['isRegister'] ?? false;
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    remainingSeconds.value = 90;
    canResend.value = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value == 0) {
        canResend.value = true;
        timer.cancel();
      } else {
        remainingSeconds.value--;
      }
    });
  }

  String get timerText {
    int minutes = remainingSeconds.value ~/ 60;
    int seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> verifyOtp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    otpError.value = '';
    final bool isFormValid = formKey.currentState?.validate() ?? false;
    final otpStr = pinController.text.trim();

    if (!isFormValid || otpStr.length < 6) {
      return;
    }

    final otpCode = int.tryParse(otpStr);
    if (otpCode == null) {
      otpError.value = 'Invalid OTP format';
      return;
    }

    try {
      isLoading.value = true;
      final response = await _authService.verifyOtp(
        email: email,
        otp: otpCode,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? 'Email verified successfully',
          isError: false,
        );

        FocusManager.instance.primaryFocus?.unfocus();
        await Future.delayed(const Duration(milliseconds: 300));

        if (!isRegister) {
          // ─── Forgot Password Flow ───
          String resetToken = '';
          final rawData = response.data?['data'];
          if (rawData is String) {
            resetToken = rawData;
          } else if (rawData is Map) {
            resetToken = rawData['resetToken']?.toString() ??
                rawData['token']?.toString() ??
                '';
          }

          Get.toNamed(
            Routes.resetpasswordthreeView,
            arguments: {
              'resetToken': resetToken,
              'email': email,
            },
          );
          return;
        }

        final rawData = response.data?['data'];
        final Map<String, dynamic> authData =
            rawData is Map<String, dynamic> ? rawData : {};
        final bool isApproved = authData['isApproved'] == true;
        final bool isOnboard = authData['isOnboard'] == true;
        final String appState =
            (authData['appState'] ?? '').toString().toUpperCase();
        final String rejectionReason =
            authData['rejectionReason']?.toString() ?? '';

        if (appState == 'REJECTED') {
          Get.offAllNamed(
            Routes.applicationNotApprovedView,
            arguments: {
              'reason': rejectionReason.isNotEmpty
                  ? rejectionReason
                  : 'Incomplete documents or vehicle not meeting standards',
              'title': 'Application Not Approved',
              'description':
                  "Unfortunately, we couldn't approve your application at this time.",
            },
          );
        } else if (isApproved) {
          Get.offAllNamed(Routes.bottomNabbarView);
        } else if (!isOnboard) {
          Get.offAllNamed(Routes.vehicleinformationView);
        } else {
          Get.offAllNamed(Routes.applicationSubmitedView);
        }
      } else {
        final msg = response.data?['message'] ?? 'OTP verification failed';
        otpError.value = msg;
      }
    } catch (e) {
      Helpers.error('OTP verification error: $e');
      otpError.value = 'OTP verification failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResend.value) return;
    try {
      isLoading.value = true;
      final response = isRegister
          ? await _authService.resendOtp(email)
          : await _authService.forgotPassword(email);

      final msg = response.data?['message'] ??
          (isRegister
              ? 'OTP Resent Successfully'
              : 'A new verification code has been sent to your email.');
      Helpers.showCustomSnackBar(msg, isError: false);
      pinController.clear();
      startTimer();
    } catch (e) {
      Helpers.showCustomSnackBar(e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    pinController.dispose();
    super.onClose();
  }
}
