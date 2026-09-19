import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/modules/my_schedule/controllers/my_schedule_controller.dart';
import 'package:moeb_26/modules/my_schedule/models/my_schedule_job_model.dart';
import 'package:moeb_26/modules/my_schedule/views/widgets/add_schedule_job_sheet.dart';
import 'package:moeb_26/modules/my_schedule/views/widgets/schedule_calendar_widget.dart';
import 'package:moeb_26/modules/my_schedule/views/schedule_job_detail_view.dart';

class MyScheduleView extends GetView<MyScheduleController> {
  const MyScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: const CustomSubAppBar(title: "My Schedule"),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddJobSheet(context),
        backgroundColor: AppColors.primaryColor, // Color(0xFFFFDCA1)
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          "Add Booking",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          // Interactive Week/Month Calendar Widget
          const ScheduleCalendarWidget(),

          SizedBox(height: 10.h),

          // Main Jobs List / Empty State
          Expanded(
            child: Obx(() {
              final jobs = controller.selectedDateJobs;
              if (jobs.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView.builder(
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  top: 8.h,
                  bottom: 95
                      .h, // Bottom spacing so scrolling content moves above FAB
                ),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  return _buildJobCard(context, jobs[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // Job Card Widget
  Widget _buildJobCard(BuildContext context, MyScheduleJobModel job) {
    final isDispatched = job.isDispatchedToNetwork;
    final vehicleStyle = VehicleTypeColors.getVehicleStyle(job.vehicleType);

    return GestureDetector(
      onTap: () => Get.to(() => ScheduleJobDetailView(job: job)),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDispatched
                ? AppColors.primaryColor.withValues(alpha: 0.6)
                : const Color(0xFF24242A),
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
            if (isDispatched) ...[
              Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: 13.sp,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "DISPATCHED TO NETWORK",
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Header Row: Time & Vehicle Type & Price
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222228),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 13.sp,
                        color: AppColors.gray100,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        DateFormat('hh:mm a').format(job.pickupDateTime),
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
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
                    job.vehicleType,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (job.fare.isNotEmpty)
                  Text(
                    job.fare,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
              ],
            ),

            SizedBox(height: 14.h),

            // Client Name & Contact Actions (SMS & Call)
            Row(
              children: [
                CircleAvatar(
                  radius: 17.r,
                  backgroundColor: const Color(0xFF24242A),
                  child: Icon(Icons.person, size: 18.sp, color: Colors.white70),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.clientName,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        job.clientPhone,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppColors.gray100,
                        ),
                      ),
                    ],
                  ),
                ),
                // Text Message (SMS) Icon Button
                GestureDetector(
                  onTap: () => controller.sendTextMessage(job.clientPhone),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFF24242A),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16.sp,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Call Phone Icon Button
                GestureDetector(
                  onTap: () => controller.makePhoneCall(job.clientPhone),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFF24242A),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone,
                      size: 16.sp,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),
            const Divider(height: 1, color: Color(0xFF24242A)),
            SizedBox(height: 12.h),

            // Route Visualiser: Pickup -> Dropoff
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 9.r,
                      height: 9.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 2),
                        color: Colors.transparent,
                      ),
                    ),
                    Container(
                      width: 1.5.w,
                      height: 24.h,
                      color: const Color(0xFF33333D),
                    ),
                    Container(
                      width: 9.r,
                      height: 9.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.pickupLocation,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        job.dropoffLocation,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),
            const Divider(height: 1, color: Color(0xFF24242A)),
            SizedBox(height: 10.h),

            // Sleek Footer: Payment Status Pill & "View Details >" link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Paid / Unpaid Status Chip (Read Only on List Page)
                AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: job.isPaid
                          ? const Color(0xFF102A1C)
                          : const Color(0xFF2C1618),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: job.isPaid
                            ? const Color(0xFF166534)
                            : const Color(0xFF991B1B),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          job.isPaid
                              ? Icons.check_circle_rounded
                              : Icons.pending_actions_rounded,
                          size: 12.sp,
                          color: job.isPaid
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFF87171),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          job.isPaid ? "PAID" : "UNPAID",
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: job.isPaid
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFF87171),
                          ),
                        ),
                      ],
                    ),
                  ),
                // "View Details >" Prompt
                Row(
                  children: [
                    Text(
                      "View Details",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11.sp,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState(BuildContext context) {
    final dateStr = DateFormat(
      'EEEE, MMM d',
    ).format(controller.selectedDate.value);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 75.r,
              height: 75.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF141416),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 34.sp,
                color: AppColors.gray100,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "No bookings for $dateStr",
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              "Your direct schedule is clear for this date. You can add a new private booking anytime.",
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppColors.gray100,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openAddJobSheet(BuildContext context) {
    Get.to(() => const AddScheduleJobSheet());
  }
}
