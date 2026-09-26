import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/auth_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';

class SigninController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final errorMessage = ''.obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ─── Toggle Password Visibility ──────────────────────────────
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  bool _isUnverifiedEmail(String message) {
    final lower = message.toLowerCase();
    return lower.contains('verify your email') ||
        lower.contains('verification code') ||
        lower.contains('verify email') ||
        lower.contains('not verified');
  }

  Future<void> _handleUnverifiedEmail(String email, String message) async {
    Helpers.showCustomSnackBar(
      message.isNotEmpty
          ? message
          : 'Please verify your email first. We sent a verification code to your email address.',
      isError: false,
    );

    try {
      await _authService.resendOtp(email);
    } catch (e) {
      debugPrint("resendOtp during login unverified email error: $e");
    }

    Get.toNamed(
      Routes.otpVerificationView,
      arguments: {'email': email, 'isRegister': true},
    );
  }

  // ─── Login ───────────────────────────────────────────────────
  Future<void> login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (formKey.currentState?.validate() != true) return;

    isLoading.value = true;
    errorMessage.value = '';

    final String email = emailController.text.trim();
    final String password = passwordController.text;

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authData = response.data?['data'] ?? {};
        final bool isApproved = authData['isApproved'] == true;
        final bool isOnboard = authData['isOnboard'] == true;
        final String appState = (authData['appState'] ?? '')
            .toString()
            .toUpperCase();
        final String rejectionReason =
            authData['rejectionReason']?.toString() ?? '';

        if (appState == 'REJECTED') {
          Helpers.showCustomSnackBar(
            'Your application has been rejected',
            isError: true,
          );
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
          Helpers.showCustomSnackBar('Login successful', isError: false);
          Get.offAllNamed(Routes.bottomNabbarView);
        } else if (!isOnboard) {
          Helpers.showCustomSnackBar(
            'Please complete vehicle information',
            isError: false,
          );
          Get.offAllNamed(Routes.vehicleinformationView);
        } else {
          Helpers.showCustomSnackBar(
            'Your application is under review',
            isError: false,
          );
          Get.offAllNamed(Routes.applicationSubmitedView);
        }
      } else {
        final String errorMsg =
            response.data?['message'] ?? 'Invalid email or password';
        if (_isUnverifiedEmail(errorMsg)) {
          await _handleUnverifiedEmail(email, errorMsg);
          return;
        }
        errorMessage.value = errorMsg;
        Helpers.showCustomSnackBar(errorMsg, isError: true);
      }
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final String errorMsg =
          (responseData is Map ? responseData['message']?.toString() : null) ??
          e.message ??
          'Login failed. Please try again.';

      if (_isUnverifiedEmail(errorMsg)) {
        await _handleUnverifiedEmail(email, errorMsg);
        return;
      }

      Helpers.showDebugLog("login error => $e");
      errorMessage.value = errorMsg;
      Helpers.showCustomSnackBar(errorMsg, isError: true);
    } catch (e) {
      Helpers.showDebugLog("login error => $e");
      errorMessage.value = 'Login failed. Please try again.';
      Helpers.showCustomSnackBar(
        'Login failed. Please try again.',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    emailController.clear();
    passwordController.clear();
    isLoading.value = false;
    errorMessage.value = '';
  }

  // ─── Dispose ─────────────────────────────────────────────────
  @override
  void onClose() {
    super.onClose();
  }
}
