import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/modules/subscription/controllers/subscription_controller.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';

class SubscriptionView extends StatelessWidget {
  SubscriptionView({super.key});

  final SubscriptionController controller = Get.put(SubscriptionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // --- TOP BAR ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF282828),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                  Text(
                    'Subscription',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 38.w),
                ],
              ),
            ),

            // --- MAIN CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 8.h),
                    // --- FLOATING ICON BADGE ---
                    Container(
                      width: 68.w,
                      height: 68.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFDCA1), Color(0xFFFEDB9B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.black,
                        size: 38.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // --- UNIFIED TITLE & SUBTITLE ---
                    Text(
                      controller.planName,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFEDB9B),
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Unlock Chauffeur Privileges & Maximize Earnings',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9E9E9E),
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 22.h),

                    // --- PRICING CARD ---
                    Obx(() {
                      final isSelected = !controller.isPremium.value;
                      return GestureDetector(
                        onTap: () {},
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(18.r),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF231808),
                                Color(0xFF17130C),
                                Color(0xFF111111),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : const Color(0xFF2C2C2C),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFDCA1),
                                          Color(0xFFFEDB9B),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      'YEARLY PLAN • SAVE 60%',
                                      style: GoogleFonts.inter(
                                        color: Colors.black,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 22.w,
                                    height: 22.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primaryColor
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : const Color(0xFF555555),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            size: 14.sp,
                                            color: Colors.black,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                              SizedBox(height: 14.h),

                              if (controller.hasProduct) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      controller.planPrice,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 32.sp,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      controller.planPeriod,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFA1A1AA),
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    controller.billingDescription,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF71717A),
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: const Color(0xFFE57373),
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Product Not Found',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFE57373),
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Could not fetch product details from Store.',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF9E9E9E),
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 22.h),

                    // --- FEATURES LIST ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Included Privileges',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD5C4AB),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: const Color(0xFF242424),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      child: Column(
                        children: controller.features.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final feature = entry.value;
                          final isLast =
                              index == controller.features.length - 1;

                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.r),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                      child: Icon(
                                        _getFeatureIcon(feature['icon']!),
                                        color: AppColors.primaryColor,
                                        size: 19.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (feature['isNew'] == 'true') ...[
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6.w,
                                                    vertical: 2.h,
                                                  ),
                                                  margin: EdgeInsets.only(right: 6.w),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.orange100,
                                                    borderRadius: BorderRadius.circular(4.r),
                                                  ),
                                                  child: Text(
                                                    'NEW',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.black,
                                                      fontSize: 9.sp,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  feature['title']!,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 13.5.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            feature['subtitle']!,
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF8E8E93),
                                              fontSize: 11.sp,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.all(3.r),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primaryColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: AppColors.primaryColor,
                                        size: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                const Divider(
                                  color: Color(0xFF222222),
                                  height: 1,
                                  thickness: 1,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),

            // --- BOTTOM CTA BUTTON ---
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                border: Border(
                  top: BorderSide(color: Color(0xFF222222), width: 1),
                ),
              ),
              child: Obx(() {
                final isPremium = controller.isPremium.value;
                final isLoading = controller.isLoading.value;
                if (isPremium) {
                  // ─── Already Subscribed ───────────────────────────────────
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: 14.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1A2A1A),
                              Color(0xFF112211),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: const Color(0xFF2E7D32),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: const Color(0xFF4CAF50),
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'You are a Premium Member',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF81C784),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Manage your subscription in App Settings.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF71717A),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  );
                }
                // ─── Not Subscribed ───────────────────────────────────────
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomButton(
                      text: 'Subscribe Now • ${controller.planPrice}/Year',
                      loading: isLoading,
                      onPressed: isLoading ? () {} : () => controller.subscribe(),
                      icon: Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.black,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    GestureDetector(
                      onTap: isLoading ? null : () => controller.restorePurchases(),
                      child: Text(
                        'Restore Purchases',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFEDB9B),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFFFEDB9B),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Auto-renews at ${controller.planPrice}/year. Cancel anytime in App Settings.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF71717A),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFeatureIcon(String iconName) {
    switch (iconName) {
      case 'job':
        return Icons.work_outline_rounded;
      case 'network':
        return Icons.groups_outlined;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'invoice':
        return Icons.receipt_long_outlined;
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'marketplace':
        return Icons.shopping_bag_outlined;
      case 'deals':
        return Icons.local_offer_outlined;
      case 'crown':
        return Icons.workspace_premium_rounded;
      case 'percent':
        return Icons.percent_rounded;
      case 'badge':
        return Icons.verified_user_rounded;
      case 'support':
        return Icons.support_agent_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
