import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/validators.dart';
import '../../../../core/widgets/CustomButton.dart';
import '../../../../core/widgets/CustomText.dart';
import '../../../../core/widgets/CustomTextField.dart';
import '../../../../core/widgets/CustomTextGary.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordThreeView extends GetView<ResetPasswordController> {
  const ResetPasswordThreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: controller.formKey,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CustomText(text: "Forget Password"),
                  ),
                  SizedBox(height: 30.h),
                  CustomTextgray(
                    text:
                        "Enter your email address and we'll send you a link to reset your password.",
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: 26.h),

                  // ── New Password ──
                  Obx(
                    () => Customtextfield(
                      controller: controller.passwordController,
                      hintText: "New Password",
                      obscureText: !controller.isPasswordVisible.value,
                      textInputType: TextInputType.visiblePassword,
                      validator: (value) => Validators.password(
                        value,
                        minLength: 8,
                        requireDigit: true,
                        requireUppercase: true,
                        requireSpecialChar: true,
                      ),
                      prefixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.gray100,
                        ),
                        onPressed: controller.togglePassword,
                      ),
                    ),
                  ),
                  SizedBox(height: 26.h),

                  // ── Confirm Password ──
                  Obx(
                    () => Customtextfield(
                      controller: controller.confirmPasswordController,
                      hintText: "Confirm New Password",
                      obscureText: !controller.isPasswordVisibleTwo.value,
                      textInputType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter Confirm New Password";
                        }
                        if (value != controller.passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                      prefixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisibleTwo.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.gray100,
                        ),
                        onPressed: controller.toggleConfirmPassword,
                      ),
                    ),
                  ),
                  SizedBox(height: 50.h),

                  // ── Reset Button ──
                  CustomButton(
                    text: "Reset Password",
                    onPressed: () {
                      Get.offAllNamed(Routes.successResetPasswordView);
                    },
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
