import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/app_const.dart';
import '../../../../core/widgets/CustomButton.dart';
import '../../../../core/widgets/CustomText.dart';
import '../../../../core/widgets/CustomTextField.dart';
import '../../../../core/widgets/CustomTextGary.dart';
import '../../../../core/widgets/custom_sub_appbar.dart';
import '../controllers/forget_password_controller.dart';

class ResetPasswordView extends GetView<ForgotPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: const CustomSubAppBar(
          title: "Forgot Password",
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
                        Icons.lock_reset_rounded,
                        color: const Color(0xFFFFDCA1),
                        size: 38.sp,
                      ),
                    ),
                  ),

                  CustomText(
                    text: "Forgot Password?",
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 8.h),
                  CustomTextgray(
                    text:
                        "Enter your registered email address to receive a 6-digit verification code to reset your password.",
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: 28.h),

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
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.gray100,
                      size: 20.sp,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Enter your email";
                      }
                      if (!AppString.emailRegexp.hasMatch(value.trim())) {
                        return "Enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32.h),

                  Obx(
                    () => CustomButton(
                      loading: controller.isLoading.value,
                      text: "Send Verification Code",
                      onPressed: () {
                        if (!controller.isLoading.value) {
                          controller.forgotPassword();
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomTextgray(
                        text: "Remember your password?",
                        fontSize: 14.sp,
                        color: AppColors.gray100,
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => Get.offNamed(Routes.signinView),
                        child: Text(
                          "Sign In",
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFDCA1),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
