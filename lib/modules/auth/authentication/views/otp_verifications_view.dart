import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/otp_verification_controller.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationView extends GetView<OtpController> {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium Pin Themes
    final defaultPinTheme = PinTheme(
      width: 46.w,
      height: 46.w,
      textStyle: GoogleFonts.inter(
        fontSize: 18.sp,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFF1A1610),
        border: Border.all(color: const Color(0xFFD08700), width: 2.0),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFF181818),
        border: Border.all(
          color: const Color(0xFFD08700).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomSubAppBar(title: "OTP Verification"),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 10.h),

                  // ========== Hero Badge Icon ==========
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      color: Colors.white,
                      size: 36.sp,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ========== Title & Subtitle ==========
                  CustomText(
                    text: "Verify Your Email",
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 8.h),
                  CustomTextgray(
                    text: "Enter the 6-digit code sent to your email",
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: 6.h),
                  
                  // Dynamic Email Display Badge
                  if (controller.email.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFF364153)),
                      ),
                      child: Text(
                        controller.email,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFDCA1),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  SizedBox(height: 36.h),

                  // ========== Pinput Fields ==========
                  Obx(
                    () => Pinput(
                      length: 6,
                      controller: controller.pinController,
                      errorText: controller.otpError.value.isNotEmpty
                          ? controller.otpError.value
                          : null,
                      separatorBuilder: (index) => SizedBox(width: 8.w),
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      onChanged: (_) {
                        if (controller.otpError.value.isNotEmpty) {
                          controller.otpError.value = '';
                        }
                      },
                      onCompleted: (pin) => controller.verifyOtp(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        if (value.length < 6) {
                          return 'OTP must be 6 digits';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Enter numbers only';
                        }
                        return null;
                      },
                      forceErrorState: controller.otpError.value.isNotEmpty,
                      errorTextStyle: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // ========== Timer Countdown Badge ==========
                  Obx(
                    () => Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFF1E1E1E)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16.sp,
                            color: const Color(0xFF9EA3AE),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            controller.timerText,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9EA3AE),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // ========== Action Button ==========
                  Obx(
                    () => CustomButton(
                      text: "Verify & Continue",
                      loading: controller.isLoading.value,
                      onPressed: () => controller.verifyOtp(),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ========== Resend Code Option ==========
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomTextgray(
                          text: "Didn't receive code?",
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9EA3AE),
                        ),
                        SizedBox(width: 6.w),
                        GestureDetector(
                          onTap: controller.canResend.value
                              ? () => controller.resendOtp()
                              : null,
                          child: Text(
                            "Resend Code",
                            style: GoogleFonts.inter(
                              color: controller.canResend.value
                                  ? const Color(0xFFFFDCA1)
                                  : Colors.grey,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              decoration: controller.canResend.value
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
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
