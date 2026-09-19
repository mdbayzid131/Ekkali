import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';
import 'package:moeb_26/data/models/my_rides_model.dart';
import '../../../core/widgets/Custom_Card_Ditails.dart';

/// Review Status Screen
/// Shows application submission status with animated steps
class RequestUnderReviewView extends StatelessWidget {
  const RequestUnderReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the ride data passed from the previous screen
    final RideData? ride = Get.arguments as RideData?;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Container(
              width: 40.w,
              height: 40.w,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: SvgPicture.asset(
                AppIcons.cross_icon,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              CustomText(
                text: "Application Submitted",
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              CustomTextgray(
                text: "Your application is under review by the job poster",
                fontSize: 14.sp,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),

              // Animated Timeline Steps
              _buildTimelineStep(
                title: "Application Received",
                subtitle: "Your profile has been shared",
                icon: Icons.check,
                isCompleted: true,
                isActive: false,
              ),
              _buildTimelineConnector(isCompleted: true),
              _buildTimelineStep(
                title: "Under Review",
                subtitle: "Job poster is reviewing your request",
                icon: Icons.access_time,
                isCompleted: false,
                isActive: true,
              ),
              _buildTimelineConnector(isCompleted: false),
              _buildTimelineStep(
                title: "Decision",
                subtitle: "You will be notified once approved",
                icon: Icons.check_circle_outline,
                isCompleted: false,
                isActive: false,
              ),

              SizedBox(height: 35.h),

              // Job Details Card
              if (ride != null)
                GestureDetector(
                  onTap: () {
                    // Handle tap on the card
                    Get.toNamed(Routes.rideDetailsView, arguments: ride);
                  },
                  child: Builder(
                    builder: (context) {
                      String displayDateTime = "N/A";
                      if (ride.asap == true) {
                        displayDateTime = "ASAP";
                      } else {
                        String timeStr = ride.time ?? "";
                        if (ride.date != null && ride.date!.isNotEmpty) {
                          try {
                            final parsedDate = DateTime.parse(ride.date!);
                            final dateFormatted =
                                DateFormat('EEE, MMM dd').format(parsedDate);
                            displayDateTime = timeStr.isNotEmpty
                                ? "$dateFormatted · $timeStr"
                                : dateFormatted;
                          } catch (_) {
                            displayDateTime = timeStr.isNotEmpty
                                ? "${ride.date} · $timeStr"
                                : ride.date!;
                          }
                        } else {
                          displayDateTime = timeStr.isNotEmpty ? timeStr : "N/A";
                        }
                      }

                      return CustomJobDetailsCard(
                        // Location details
                        pickupLocation: ride.pickupLocation ?? "N/A",
                        dropoffLocation: ride.dropoffLocation ?? "N/A",

                        // Job information
                        flightNumber: ride.flightNumber ?? "N/A",
                        dateTime: displayDateTime,
                        vehicleType: ride.vehicleType ?? "N/A",
                        jobPoster:
                            ride.createdBy?.nickname != null &&
                                ride.createdBy!.nickname!.isNotEmpty
                            ? ride.createdBy!.nickname!
                            : (ride.createdBy?.name ?? "Unknown"),
                        company: ride.createdBy?.company ?? "Unknown",
                        payment: ride.paymentType ?? "N/A",
                        amount: "\$${ride.paymentAmount ?? 0}",

                        // Optional: Custom colors
                        backgroundColor: const Color(0xFF1C1C1C),
                        borderColor: const Color(0xFF2A2A2A),
                        labelColor: Colors.grey,
                        valueColor: Colors.white,
                        iconColor: Colors.grey,
                      );
                    },
                  ),
                ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single step in the timeline
  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
  }) {
    final Color iconColor = isCompleted
        ? const Color(0xFFD08700)
        : isActive
            ? const Color(0xFFFEDB9B)
            : const Color(0xFF6B7280);

    final Color bgColor = isCompleted || isActive
        ? const Color(0xFF1C1810)
        : const Color(0xFF1E1E1E);

    final Color borderColor = isCompleted || isActive
        ? const Color(0xFFD08700).withValues(alpha: 0.5)
        : const Color(0xFF2C2C2C);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Icon(icon, color: iconColor, size: 20.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: title,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: isCompleted || isActive ? Colors.white : Colors.grey,
              ),
              SizedBox(height: 3.h),
              CustomTextgray(
                text: subtitle,
                fontSize: 13.sp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds connector line between timeline steps
  Widget _buildTimelineConnector({required bool isCompleted}) {
    return Row(
      children: [
        SizedBox(
          width: 40.w,
          child: Center(
            child: Container(
              width: 2.w,
              height: 24.h,
              color: isCompleted
                  ? const Color(0xFFD08700)
                  : const Color(0xFF2C2C2C),
            ),
          ),
        ),
      ],
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
}
