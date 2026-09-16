// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/Custom_Job_Button.dart';
import 'package:moeb_26/data/models/job_offer_model.dart';
import 'package:moeb_26/modules/jobs_offers/controllers/Job_offer_controller.dart';
import 'package:moeb_26/modules/jobs_offers/widgets/JobOfferCard.dart';
import 'package:moeb_26/modules/jobs_offers/widgets/JobOfferDetailSheet.dart';
import '../../../core/widgets/Custom_AppBar.dart';
import '../../jobs_posts/views/job_post_sheet_tabbar_view.dart';

class JobOfferView extends StatelessWidget {
  const JobOfferView({super.key});

  @override
  Widget build(BuildContext context) {
    final JobOfferController controller = Get.isRegistered<JobOfferController>()
        ? Get.find<JobOfferController>()
        : Get.put(JobOfferController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(title: "Offers", notificationCount: 3),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 15.h),
            // Top Action Buttons Header
            CustomJobButton(
              text: "New Job",
              padding: EdgeInsets.symmetric(
                vertical: 14.h,
                horizontal: 8.w,
              ),
              onPressed: () {
                Get.to(() => const JobPostSheetTabBarView());
              },
            ),
            // Row(
            //   children: [
            //     Expanded(
            //       child: CustomJobButton(
            //         text: "New Job",
            //         padding: EdgeInsets.symmetric(
            //           vertical: 12.h,
            //           horizontal: 8.w,
            //         ),
            //         onPressed: () {
            //           Get.to(() => const JobPostSheetTabBarView());
            //         },
            //       ),
            //     ),
            //     SizedBox(width: 12.w),
            //     Expanded(
            //       child: CustomJobButton(
            //         text: "My Jobs",
            //         iconPath: AppIcons.edit_icon_myjob,
            //         iconSize: 18.w,
            //         padding: EdgeInsets.symmetric(
            //           vertical: 12.h,
            //           horizontal: 8.w,
            //         ),
            //         onPressed: () {
            //           Get.toNamed(Routes.myJobsView);
            //         },
            //       ),
            //     ),
            //   ],
            // ),
            SizedBox(height: 15.h),

            // Job Offers List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.jobOffers.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                if (controller.errorMessage.isNotEmpty &&
                    controller.jobOffers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 40.sp,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          controller.errorMessage.value,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () => controller.fetchJobOffers(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            "Try Again",
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.groupedJobOffers.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.primaryColor,
                    backgroundColor: const Color(0xFF1E1E1E),
                    onRefresh: () => controller.fetchJobOffers(isRefresh: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(height: 120.h),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.work_outline_rounded,
                                color: Colors.grey[600],
                                size: 48.sp,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                "No job offers available right now",
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Pull down to refresh new broadcast rides",
                                style: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final groupEntries =
                    controller.groupedJobOffers.entries.toList();

                return RefreshIndicator(
                  color: AppColors.primaryColor,
                  backgroundColor: const Color(0xFF1E1E1E),
                  onRefresh: () => controller.fetchJobOffers(isRefresh: true),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: groupEntries.length,
                    padding: EdgeInsets.only(bottom: 20.h),
                    itemBuilder: (context, groupIndex) {
                      final entry = groupEntries[groupIndex];
                      final String dateHeader = entry.key;
                      final List<JobOfferModel> offers = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Section Header
                          Padding(
                            padding: EdgeInsets.only(
                              top: 15.h,
                              bottom: 10.h,
                              left: 4.w,
                            ),
                            child: Text(
                              dateHeader,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...offers.map((job) {
                            return JobOfferCard(
                              time: job.displayTime,
                              pickupLocation: job.pickup,
                              dropoffLocation: job.dropoff,
                              passengerName: job.passengerName,
                              companyName: job.companyName,
                              vehicleType: job.vehicleType,
                              price: job.paymentAmount.toStringAsFixed(2),
                              paymentType: job.paymentType,
                              onTap: () {
                                Get.bottomSheet(
                                  JobOfferDetailSheet(
                                    title: "Job Offer Details",
                                    bookingNo: job.bookingNo,
                                    dateTimeStr: job.asap
                                        ? "$dateHeader • ASAP"
                                        : "$dateHeader • ${job.displayTime}",
                                    pickupLocation: job.pickup,
                                    pickupNotes: job.pickupNotes,
                                    dropoffLocation: job.dropoff,
                                    dropoffNotes: job.dropoffNotes,
                                    passengerName: job.passengerName,
                                    companyName: job.companyName,
                                    vehicleType: job.vehicleType,
                                    paymentType: job.paymentType,
                                    amount: job.paymentAmount.toStringAsFixed(2),
                                    flightNumber: job.flightNumber,
                                    specialInstructions: job.instruction,
                                    actionButtonText: "Apply to Job",
                                    onApplyPressed: () {
                                      controller.applyToJob(job);
                                    },
                                  ),
                                  isScrollControlled: true,
                                  ignoreSafeArea: false,
                                );
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
