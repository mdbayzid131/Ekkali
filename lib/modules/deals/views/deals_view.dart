import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/data/models/deals_model.dart';
import '../controllers/deals_controller.dart';
import '../../../core/widgets/QrPopup.dart';

class DealsView extends StatelessWidget {
  DealsView({super.key});

  // Initialize the controller
  final DealsController controller = Get.find<DealsController>();

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
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Deals',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchDeals(),
        color: AppColors.primaryColor,
        child: Obx(() {
          if (controller.isLoading.value && controller.dealsList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          return Stack(
            children: [
              // Handle empty state
              if (controller.dealsList.isEmpty)
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: 600.h, // Sufficient height for scroll
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Empty State Box Icon (Placeholder wrapper)
                        Container(
                          padding: EdgeInsets.all(40.w),
                          decoration: BoxDecoration(
                            color: const Color(0xff1C1C1C),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey[700],
                            size: 60.sp,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          "No deals at this time",
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Handle list of deals
                ListView.builder(
                  controller: controller.scrollController,
                  padding: EdgeInsets.fromLTRB(20.w, 10.w, 20.w, 10.w),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.dealsList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == controller.dealsList.length) {
                      return Obx(
                        () => controller.isLoadMore.value
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.h),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      );
                    }
                    final deal = controller.dealsList[index];
                    return DealsCard(deal: deal, controller: controller);
                  },
                ),

              // Overlay loader when fetching fresh data but not the first time
              if (controller.isLoading.value && controller.dealsList.isNotEmpty)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryColor),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class DealsCard extends StatelessWidget {
  final DealsItem deal;
  final DealsController controller;

  const DealsCard({super.key, required this.deal, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark card background
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xff242424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge
          Row(
            children: [
              SvgPicture.asset(
                AppIcons.service_icon, // Using the tag/service icon
                height: 18.sp,
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xff1E1E1E),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xff242424)),
                ),
                child: Text(
                  deal.tags.isNotEmpty ? deal.tags.first : "Deal",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // Title
          Text(
            deal.title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          // Description
          Text(
            deal.description,
            style: GoogleFonts.inter(
              color: const Color(0xff949494),
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 10.h),
          // Promo Code Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xff1E1E1E),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xff242424)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Promo Code",
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      deal.promoCode,
                      style: GoogleFonts.inter(
                        color: AppColors.primaryColor, // Gold color
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                // Copy Button
                GestureDetector(
                  onTap: () => controller.copyToClipboard(deal.promoCode),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "Copy",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          // Footer: Expiry and Use QR Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey[700],
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Expires ${DateFormat('MMM dd').format(deal.expiryDate)}",
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
              // Use QR Button
              CustomButton(
                text: "Use QR",
                onPressed: () {
                  Get.dialog(QrPopup(qrCodeData: deal.qrCode));
                },
                width: null,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 10.h,
                ),
                icon: SvgPicture.asset(
                  AppIcons.qr_icon,
                  height: 16.sp,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
