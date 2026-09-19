import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import '../controllers/ride_completed_controller.dart';

class RideCompletedView extends StatelessWidget {
  RideCompletedView({super.key});

  final RideCompletedController controller =
      Get.find<RideCompletedController>();

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return "Poor 😞";
      case 2:
        return "Fair 😐";
      case 3:
        return "Good 🙂";
      case 4:
        return "Very Good 😊";
      case 5:
        return "Excellent! 🌟";
      default:
        return "Tap a star to rate";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20.sp,
              ),
              onPressed: () => controller.skipReview(),
            ),
            title: Text(
              'Ride Completed',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: const Color(0xFFA1A1A1),
                  size: 24.sp,
                ),
                onPressed: () => controller.skipReview(),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 12.h),

              // Hero Completed Icon & Glow Badge
              Center(
                child: Container(
                  width: 84.w,
                  height: 84.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 64.w,
                      height: 64.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 40.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18.h),

              // Title & Subtitle
              Text(
                "Ride Completed Successfully!",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                "Thank you for completing the job. How was your experience?",
                style: GoogleFonts.inter(
                  color: const Color(0xFFA1A1A1),
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28.h),

              // Rating Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF26262E),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Rate the Job Poster",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Interactive Star Row
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final bool isSelected =
                              index < controller.rating.value;
                          return GestureDetector(
                            onTap: () => controller.updateRating(index + 1),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w),
                              child: AnimatedScale(
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  isSelected
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : const Color(0xFF4A4A5A),
                                  size: 38.sp,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Rating Description label
                    Obx(
                      () => Text(
                        _getRatingLabel(controller.rating.value),
                        style: GoogleFonts.inter(
                          color: controller.rating.value > 0
                              ? AppColors.primaryColor
                              : const Color(0xFF71717A),
                          fontSize: 13.sp,
                          fontWeight: controller.rating.value > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),

              // Feedback Input Box
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF26262E),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          color: const Color(0xFFA1A1A1),
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Share feedback (optional)",
                          style: GoogleFonts.inter(
                            color: const Color(0xFFA1A1A1),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: controller.feedbackController,
                      maxLines: 4,
                      maxLength: 500,
                      onChanged: (val) => controller.feedback.value = val,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                      cursorColor: AppColors.primaryColor,
                      decoration: InputDecoration(
                        hintText:
                            "Write your feedback or note about this ride...",
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 13.sp,
                        ),
                        counterText: "",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Divider(color: const Color(0xFF26262E), height: 16.h),
                    Obx(
                      () => Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${controller.feedback.value.length}/500",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF71717A),
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),

              // Submit Button
              Obx(
                () => controller.isLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      )
                    : CustomButton(
                        text: "Submit Review",
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.black,
                        fontWeight: FontWeight.bold,
                        onPressed: () {
                          controller.submitReview();
                        },
                      ),
              ),
              SizedBox(height: 12.h),

              // Skip Button
              CustomButton(
                text: "Skip for now",
                backgroundColor: const Color(0xFF18181B),
                textColor: const Color(0xFFA1A1A1),
                borderColor: const Color(0xFF27272A),
                onPressed: () {
                  controller.skipReview();
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
