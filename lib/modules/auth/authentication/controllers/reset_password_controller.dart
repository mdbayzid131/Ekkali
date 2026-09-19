import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/auth_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';

class ResetPasswordController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isPasswordVisibleTwo = false.obs;

  String _resetToken = '';

  @override
  void onInit() {
    super.onInit();
    _resetToken = Get.arguments?['resetToken'] ?? '';
    print('=====> RESET TOKEN: $_resetToken'); // 👈 add করো
  }

  void togglePassword() => isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPassword() =>
      isPasswordVisibleTwo.value = !isPasswordVisibleTwo.value;

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final response = await _authService.resetPassword(
        resetToken: _resetToken,
        newPassword: passwordController.text,
        confirmPassword: confirmPasswordController.text,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showCustomSnackBar(
          'Your password has been successfully reset.',
          isError: false,
        );
        Get.offAllNamed(Routes.successResetPasswordView);
        Future.delayed(const Duration(seconds: 5), () {
          Get.offAllNamed(Routes.signinView);
        });
      }
    } catch (e) {
      Helpers.showDebugLog("resetPassword error => $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
