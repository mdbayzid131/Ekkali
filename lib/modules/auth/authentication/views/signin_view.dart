import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/app_const.dart';
import 'package:moeb_26/core/utils/validators.dart';
import '../../../../core/widgets/CustomButton.dart';
import '../../../../core/widgets/CustomText.dart';
import '../../../../core/widgets/CustomTextField.dart';
import '../../../../core/widgets/CustomTextGary.dart';
import '../controllers/signin_controller.dart';

class SignInView extends GetView<SigninController> {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Form(
        key: controller.formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 100.h),
                CustomText(text: "Welcome Back"),
                SizedBox(height: 7.h),
                CustomTextgray(
                  text: "Sign in to continue to your account",
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: 20.h),
                CustomText(
                  text: "Email Address",
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
                SizedBox(height: 8.h),
                Customtextfield(
                  controller: controller.emailController,
                  hintText: "your.email@example.com",
                  obscureText: false,
                  textInputType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter your Email";
                    }
                    if (!AppString.emailRegexp.hasMatch(value)) {
                      return "Invalid Email";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                CustomText(
                  text: "Password",
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
                SizedBox(height: 8.h),
                Obx(
                  () => Customtextfield(
                    controller: controller.passwordController,
                    hintText: "Enter your password",
                    obscureText: !controller.isPasswordVisible.value,
                    textInputType: TextInputType.visiblePassword,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Enter your password";
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.gray100,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () {
                    Get.toNamed(Routes.resetPasswordView);
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CustomTextgray(
                      text: "Forgot Password?",
                      color: AppColors.gray100,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // ── Sign In Button ──
                Obx(
                  () => CustomButton(
                    text: controller.isLoading.value
                        ? "Signing In..."
                        : "Sign In",
                    onPressed: () {
                      if (!controller.isLoading.value) {
                        controller.login();
                      }
                    },
                  ),
                ),
                SizedBox(height: 30.h),
                GestureDetector(
                  onTap: () {
                    Get.toNamed(Routes.createaccountview);
                  },
                  child: Center(
                    child: CustomTextgray(
                      text: "Create Account?",
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),)
    );
  }
}
