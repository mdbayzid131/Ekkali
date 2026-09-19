import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/modules/my_schedule/controllers/my_schedule_controller.dart';
import 'package:moeb_26/modules/my_schedule/models/my_schedule_job_model.dart';
import 'package:moeb_26/modules/my_schedule/views/widgets/add_schedule_job_sheet.dart';

class ScheduleJobDetailView extends StatelessWidget {
  final MyScheduleJobModel job;

  const ScheduleJobDetailView({super.key, required this.job});

  void _confirmDeleteJob(BuildContext context, String jobId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: Text(
          "Cancel Booking?",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to remove this booking from your private schedule?",
          style: GoogleFonts.inter(color: AppColors.gray100),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "No",
              style: GoogleFonts.inter(color: AppColors.gray100),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.back(); // close dialog
              Get.back(); // return from details screen
              Get.find<MyScheduleController>().deleteJob(jobId);
            },
            child: Text(
              "Yes, Delete",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDispatchToNetwork(BuildContext context, MyScheduleJobModel job) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: Row(
          children: [
            Icon(Icons.share, color: AppColors.primaryColor, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              "Pass Job to Network?",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        content: Text(
          "Do you want to dispatch ${job.clientName}'s trip (${job.pickupLocation} -> ${job.dropoffLocation}) to the chauffeur network? You will select the target Service Area or Preferred Chauffeur.",
          style: GoogleFonts.inter(color: AppColors.gray100, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: AppColors.gray100),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Get.back();
              Get.find<MyScheduleController>().openChauffeurSelectionForDispatch(context, job);
            },
            child: Text(
              "Select Chauffeur",
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MyScheduleController controller = Get.find<MyScheduleController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: CustomSubAppBar(
        title: "Booking Details",
        actions: [
          if (!job.isDispatchedToNetwork)
            IconButton(
              icon: SvgPicture.asset(
                AppIcons.edit_icon,
                width: 18.sp,
                height: 18.sp,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              onPressed: () {
                Get.back();
                Get.to(() => AddScheduleJobSheet(existingJob: job));
              },
            ),
          IconButton(
            icon: SvgPicture.asset(
              AppIcons.delete_icon,
              width: 18.sp,
              height: 18.sp,
              colorFilter:
                  const ColorFilter.mode(Color(0xFFF87171), BlendMode.srcIn),
            ),
            onPressed: () => _confirmDeleteJob(context, job.id),
          ),
        ],
      ),
      body: Obx(() {
        // Fetch real-time job state from controller list
        final currentJob = controller.jobsList.firstWhere(
          (j) => j.id == job.id,
          orElse: () => job,
        );

        final vehicleStyle = VehicleTypeColors.getVehicleStyle(currentJob.vehicleType);
        final isDispatched = currentJob.isDispatchedToNetwork;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Privacy Banner Card
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDispatched
                              ? AppColors.primaryColor.withValues(alpha: 0.6)
                              : const Color(0xFF24242A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: isDispatched
                                  ? AppColors.primaryColor.withValues(alpha: 0.15)
                                  : const Color(0xFF222228),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDispatched ? Icons.public : Icons.lock_outline,
                              size: 18.sp,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDispatched ? "Dispatched to Public Network" : "Private Booking",
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  isDispatched
                                      ? "Visible to public chauffeurs network"
                                      : "Visible only in your private schedule",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: AppColors.gray100,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Payment Status Badge (Read-Only)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: currentJob.isPaid
                                  ? const Color(0xFF102A1C)
                                  : const Color(0xFF2C1618),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: currentJob.isPaid
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF991B1B),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentJob.isPaid
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_actions_rounded,
                                  size: 13.sp,
                                  color: currentJob.isPaid
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFF87171),
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  currentJob.isPaid ? "PAID" : "UNPAID",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: currentJob.isPaid
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFFF87171),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Date & Time & Vehicle Header Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFF24242A)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 16.sp, color: AppColors.primaryColor),
                              SizedBox(width: 8.w),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(currentJob.pickupDateTime),
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16.sp, color: AppColors.primaryColor),
                              SizedBox(width: 8.w),
                              Text(
                                DateFormat('hh:mm a').format(currentJob.pickupDateTime),
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              // Vehicle Badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: vehicleStyle is Color ? vehicleStyle : null,
                                  gradient: vehicleStyle is Gradient ? vehicleStyle : null,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  currentJob.vehicleType,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Client Info Card with Quick Action Buttons
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFF24242A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CLIENT INFORMATION",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray100,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22.r,
                                backgroundColor: const Color(0xFF24242A),
                                child: Text(
                                  currentJob.clientName.isNotEmpty ? currentJob.clientName[0].toUpperCase() : 'C',
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentJob.clientName,
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      currentJob.clientPhone,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        color: AppColors.gray100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          // Call and SMS Quick Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => controller.makePhoneCall(currentJob.clientPhone),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222228),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: const Color(0xFF33333D)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.phone, size: 16.sp, color: AppColors.primaryColor),
                                        SizedBox(width: 6.w),
                                        Text(
                                          "Call Client",
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => controller.sendTextMessage(currentJob.clientPhone),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222228),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: const Color(0xFF33333D)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chat_bubble_outline_rounded, size: 16.sp, color: AppColors.primaryColor),
                                        SizedBox(width: 6.w),
                                        Text(
                                          "Text Message",
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Route Timeline Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFF24242A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ROUTE DETAILS",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray100,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 10.r,
                                    height: 10.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white70, width: 2),
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  Container(
                                    width: 2.w,
                                    height: 36.h,
                                    color: const Color(0xFF33333D),
                                  ),
                                  Container(
                                    width: 10.r,
                                    height: 10.r,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PICKUP LOCATION",
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gray100,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      currentJob.pickupLocation,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 18.h),
                                    Text(
                                      "DROP-OFF LOCATION",
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gray100,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      currentJob.dropoffLocation.isNotEmpty
                                          ? currentJob.dropoffLocation
                                          : "As Directed",
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          const Divider(color: Color(0xFF24242A), height: 1),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Icon(Icons.flight_land,
                                  size: 16.sp, color: AppColors.primaryColor),
                              SizedBox(width: 8.w),
                              Text(
                                "FLIGHT NUMBER: ",
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray100,
                                ),
                              ),
                              Text(
                                (currentJob.flightNumber != null &&
                                        currentJob.flightNumber!.isNotEmpty)
                                    ? currentJob.flightNumber!
                                    : "Not Specified",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: (currentJob.flightNumber != null &&
                                          currentJob.flightNumber!.isNotEmpty)
                                      ? AppColors.primaryColor
                                      : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Payment & Financial Breakdown Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFF24242A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PAYMENT & FARE",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray100,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Fare",
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                currentJob.fare.isNotEmpty ? currentJob.fare : "\$0.00",
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          const Divider(color: Color(0xFF24242A), height: 1),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Payment Method",
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                currentJob.paymentMethod,
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          const Divider(color: Color(0xFF24242A), height: 1),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Payment Status",
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    currentJob.isPaid ? "PAID" : "UNPAID",
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      color: currentJob.isPaid
                                          ? const Color(0xFF4ADE80)
                                          : const Color(0xFFF87171),
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: currentJob.isPaid,
                                activeThumbColor: const Color(0xFF4ADE80),
                                activeTrackColor: const Color(0xFF166534),
                                inactiveThumbColor: const Color(0xFFF87171),
                                inactiveTrackColor: const Color(0xFF451A1A),
                                onChanged: (val) {
                                  controller.togglePaymentStatus(currentJob.id);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (currentJob.notes.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      // Special Notes Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFF24242A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BOOKING NOTES",
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray100,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              currentJob.notes,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: const BoxDecoration(
                color: Color(0xFF141416),
                border: Border(top: BorderSide(color: Color(0xFF24242A))),
              ),
              child: Row(
                children: [
                  if (!isDispatched) ...[
                    Expanded(
                      child: CustomButton(
                        text: "Edit Booking",
                        onPressed: () {
                          Get.back();
                          Get.to(() => AddScheduleJobSheet(existingJob: currentJob));
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _confirmDispatchToNetwork(context, currentJob),
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.primaryColor, width: 1.2),
                          ),
                          child: Center(
                            child: Text(
                              "Dispatch to Network",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.primaryColor, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.public, size: 16.sp, color: AppColors.primaryColor),
                            SizedBox(width: 6.w),
                            Text(
                              "Dispatched to Network",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
