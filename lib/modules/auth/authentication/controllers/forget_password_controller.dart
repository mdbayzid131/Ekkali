import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/auth_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';

class ForgotPasswordController extends GetxController {
  final AuthService _authService = Get.find();

  final isLoading = false.obs;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  // ─── Forgot Password ──────────────────────────────────────────
  Future<void> forgotPassword() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final response = await _authService.forgotPassword(
        emailController.text.trim(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final message =
            response.data['message'] ??
            'Please check your email. We have sent you a one-time passcode (OTP).';

        Helpers.showCustomSnackBar(message, isError: false);

        // Navigate to OTP screen, pass email for verification
        Get.toNamed(
          Routes.forgetotpVerificationView,
          arguments: {'email': emailController.text.trim()},
        );
      }
    } catch (e) {
      Helpers.showDebugLog("forgotPassword error => $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    emailController.clear();
    isLoading.value = false;
  }

  // ─── Dispose ──────────────────────────────────────────────────
  @override
  void onClose() {
    super.onClose();
  }
}
