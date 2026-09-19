import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/validators.dart';
import '../../../../core/widgets/CustomButton.dart';
import '../../../../core/widgets/CustomText.dart';
import '../../../../core/widgets/CustomTextField.dart';
import '../../../../core/widgets/CustomTextGary.dart';
import '../../../../core/widgets/custom_sub_appbar.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordThreeView extends GetView<ResetPasswordController> {
  const ResetPasswordThreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: const CustomSubAppBar(
          title: "Reset Password",
        ),
        body: SafeArea(
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      margin: EdgeInsets.only(top: 10.h, bottom: 24.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2C2C2C),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: const Color(0xFFFFDCA1),
                        size: 38.sp,
                      ),
                    ),
                  ),

                  CustomText(
                    text: "Create New Password",
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 8.h),
                  CustomTextgray(
                    text:
                        "Your new password must be at least 8 characters long with uppercase, digits, and special characters.",
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: 28.h),

                  CustomText(
                    text: "New Password",
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                  SizedBox(height: 8.h),
                  Obx(
                    () => Customtextfield(
                      controller: controller.passwordController,
                      hintText: "Enter new password",
                      obscureText: !controller.isPasswordVisible.value,
                      textInputType: TextInputType.visiblePassword,
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.gray100,
                        size: 20.sp,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.gray100,
                        ),
                        onPressed: controller.togglePassword,
                      ),
                      validator: (value) => Validators.password(
                        value,
                        minLength: 8,
                        requireDigit: true,
                        requireUppercase: true,
                        requireSpecialChar: true,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  CustomText(
                    text: "Confirm New Password",
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                  SizedBox(height: 8.h),
                  Obx(
                    () => Customtextfield(
                      controller: controller.confirmPasswordController,
                      hintText: "Re-enter new password",
                      obscureText: !controller.isPasswordVisibleTwo.value,
                      textInputType: TextInputType.visiblePassword,
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.gray100,
                        size: 20.sp,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisibleTwo.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.gray100,
                        ),
                        onPressed: controller.toggleConfirmPassword,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter Confirm New Password";
                        }
                        if (value != controller.passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 36.h),

                  Obx(
                    () => CustomButton(
                      loading: controller.isLoading.value,
                      text: "Reset Password",
                      onPressed: () {
                        if (!controller.isLoading.value) {
                          controller.resetPassword();
                        }
                      },
                    ),
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
