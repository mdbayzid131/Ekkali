import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';

class RideCard extends StatelessWidget {
  final String time;
  final String pickupLocation;
  final String dropoffLocation;
  final String jobPosterName;
  final String? driverName;
  final String vehicleInfo;
  final String vehicleType;
  final String? price;
  final String? paymentType;
  final String? status;
  final bool isCreatedByMe;
  final bool hasApplicant;
  final int? applicantCount;
  final VoidCallback? onTap;
  final VoidCallback? onChatTap;

  const RideCard({
    super.key,
    required this.time,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.jobPosterName,
    this.driverName,
    required this.vehicleInfo,
    required this.vehicleType,
    this.price,
    this.paymentType,
    this.status,
    this.isCreatedByMe = false,
    this.hasApplicant = false,
    this.applicantCount,
    this.onTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleStyle = VehicleTypeColors.getVehicleStyle(vehicleType);

    // Determine subtitle text and icon based on role and status
    String displaySubtitle = "";
    IconData subtitleIcon = Icons.person_outline;
    Color subtitleColor = Colors.white70;

    if (isCreatedByMe) {
      final upperStatus = (status ?? 'PENDING').toUpperCase();
      if (upperStatus == 'PENDING') {
        if (hasApplicant || (applicantCount != null && applicantCount! > 0)) {
          final count = applicantCount ?? 1;
          displaySubtitle = "$count Applicant${count > 1 ? 's' : ''} Available";
          subtitleIcon = Icons.person_search_outlined;
          subtitleColor = const Color(0xFFFEDB9B);
        } else {
          displaySubtitle = "Awaiting Chauffeur";
          subtitleIcon = Icons.hourglass_empty_rounded;
          subtitleColor = const Color(0xFF94A3B8);
        }
      } else if (upperStatus == 'ASSIGNED') {
        displaySubtitle =
            "Chauffeur: ${driverName?.isNotEmpty == true ? driverName! : 'Assigned'}";
        subtitleIcon = Icons.person_outline;
      } else if (upperStatus == 'COMPLETED' || upperStatus == 'FINISHED') {
        displaySubtitle =
            "Chauffeur: ${driverName?.isNotEmpty == true ? driverName! : 'Completed'}";
        subtitleIcon = Icons.check_circle_outline;
      } else {
        displaySubtitle = "Created by You";
        subtitleIcon = Icons.person_outline;
      }
    } else {
      final upperStatus = (status ?? 'ASSIGNED').toUpperCase();
      if (upperStatus == 'PENDING') {
        displaySubtitle = "Application Pending";
        subtitleIcon = Icons.hourglass_empty_rounded;
        subtitleColor = const Color(0xFFFEDB9B);
      } else if (upperStatus == 'ASSIGNED' || upperStatus == 'IN PROGRESS') {
        displaySubtitle = "Chauffeur: Me";
        subtitleIcon = Icons.person_outline;
        subtitleColor = Colors.white70;
      } else if (upperStatus == 'COMPLETED' || upperStatus == 'FINISHED') {
        displaySubtitle = "Chauffeur: Me";
        subtitleIcon = Icons.check_circle_outline;
        subtitleColor = Colors.white70;
      } else {
        displaySubtitle =
            jobPosterName.isNotEmpty ? jobPosterName : "Job Poster";
        subtitleIcon = Icons.person_outline;
        subtitleColor = Colors.white70;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF24242A),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Role Tag Row if created by me
            if (isCreatedByMe) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEDB9B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: const Color(0xFFFEDB9B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      "My Created Job",
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFEDB9B),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],

            // Top Main Row: Time & Price on Left, Route Connector on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Time, Price, Status
                SizedBox(
                  width: 78.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (price != null && price!.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          "\$$price",
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFEDB9B),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (status != null && status!.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusBg(status!),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            status!.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: _getStatusText(status!),
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // Right Column: Route Timeline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup Row
                      Row(
                        children: [
                          Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white70,
                                width: 2,
                              ),
                              color: Colors.transparent,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              pickupLocation,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Connecting Vertical Line
                      Padding(
                        padding: EdgeInsets.only(
                          left: 4.w,
                          top: 3.h,
                          bottom: 3.h,
                        ),
                        child: Container(
                          width: 2.w,
                          height: 16.h,
                          color: const Color(0xFF33333E),
                        ),
                      ),

                      // Dropoff Row
                      Row(
                        children: [
                          Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFEDB9B),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              dropoffLocation.isNotEmpty
                                  ? dropoffLocation
                                  : "As Directed",
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),
            Divider(color: const Color(0xFF22222A), height: 1.h, thickness: 1),
            SizedBox(height: 12.h),

            // Bottom Sub-Info Row: Driver/Poster Info on Left & Vehicle Category Badge on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Driver / Poster Info
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(subtitleIcon, color: subtitleColor, size: 15.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          displaySubtitle,
                          style: GoogleFonts.inter(
                            color: subtitleColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // Vehicle Category Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: vehicleStyle is Color ? vehicleStyle : null,
                    gradient: vehicleStyle is Gradient ? vehicleStyle : null,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    vehicleType,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBg(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
      case 'COMPLETED':
      case 'FINISHED':
        return Colors.green.withValues(alpha: 0.2);
      case 'ASSIGNED':
      case 'IN PROGRESS':
        return Colors.blue.withValues(alpha: 0.2);
      case 'PENDING':
        return const Color(0xFFD08700).withValues(alpha: 0.2);
      case 'CANCELLED':
        return Colors.red.withValues(alpha: 0.2);
      default:
        return const Color(0xFF2A2A32);
    }
  }

  Color _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
      case 'COMPLETED':
      case 'FINISHED':
        return Colors.greenAccent;
      case 'ASSIGNED':
      case 'IN PROGRESS':
        return Colors.lightBlueAccent;
      case 'PENDING':
        return const Color(0xFFFEDB9B);
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }
}
