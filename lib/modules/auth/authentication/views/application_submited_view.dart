import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/auth_service.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';

/// Review Status Screen
/// Shows application submission status with animated steps
class ApplicationSubmitedView extends StatelessWidget {
  const ApplicationSubmitedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Get.find<AuthService>().clearLocalAuth();
              Get.offAllNamed(Routes.signinView);
            },
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),

                // Clock Icon with pulse animation
                _buildClockIcon(),

                SizedBox(height: 40.h),

                // Title
                CustomText(
                  text: "Application Submitted",
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),

                SizedBox(height: 16.h),

                // Description
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: CustomTextgray(
                    text:
                        "Your application is under review by our admin team. This typically takes 24-48 hours.",
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    textAlign: TextAlign.center,
                    color: Color(0xFFF2F2F2),
                  ),
                ),

                SizedBox(height: 50.h),

                // Status Steps Container (You can use this in your widget tree)
                Column(
                  children: [
                    // Step 1: Application Submitted
                    _buildStatusStep(
                      title: "Application Submitted",
                      isCompleted: true,
                      icon:
                          Icons.check_circle_outline, // Dynamic Icon for Step 1
                    ),
                    SizedBox(height: 16.h),

                    // Step 2: Document Review
                    _buildStatusStep(
                      title: "Document Review",
                      isCompleted: false,
                      icon:
                          Icons.check_circle_outline, // Dynamic Icon for Step 2
                    ),
                    SizedBox(height: 16.h),

                    // Step 3: Final Approval
                    _buildStatusStep(
                      title: "Final Approval",
                      isCompleted: false,
                      icon:
                          Icons.privacy_tip_outlined, // Dynamic Icon for Step 3
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),

                SizedBox(height: 30.h),

                // Info Box
                _buildInfoBox(
                  title:
                      "You'll receive an email notification once your application has been reviewed. Please check your spam folder as well.",
                ),
                SizedBox(height: 10.h),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds clock icon with circular background
  Widget _buildClockIcon() {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: Color(0xFF413A3A),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.access_time_rounded, color: Colors.white, size: 50.sp),
    );
  }

  /// Builds status step with dynamic icon and title
  Widget _buildStatusStep({
    required String title,
    required bool isCompleted,
    required IconData icon, // Added the icon parameter
  }) {
    return Row(
      children: [
        // Check Circle Icon
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: Color(0xFF1E2939),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon, // Use dynamic icon passed as parameter
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 16.w),

        // Step Title
        Expanded(
          child: CustomText(
            text: title,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isCompleted ? Colors.white : Color(0xFFDEDEDE),
          ),
        ),
      ],
    );
  }

  /// Builds info notification box
  Widget _buildInfoBox({required String title}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Color(0xFF1E2939),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Color(0xFF364153), width: 1),
      ),
      child: Text(
        title,
        style: TextStyle(color: Color(0xFFDEDEDE), fontSize: 14),
      ),
    );
  }
}
