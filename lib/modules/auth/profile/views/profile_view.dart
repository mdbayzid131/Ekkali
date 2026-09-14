import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/config/constants/image_paths.dart';
import 'package:moeb_26/modules/auth/profile/controllers/profile_controller.dart';
import 'package:moeb_26/modules/auth/profile/views/personal_information_view.dart';
import 'package:moeb_26/modules/auth/profile/views/payment_information_view.dart';
import 'package:moeb_26/core/widgets/LogoutBottomSheet.dart';
import 'package:moeb_26/core/widgets/Contact_support_popup.dart';
import 'package:moeb_26/core/widgets/Custom_AppBar.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final ProfileController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: 'My Profile',
        showBackButton: false,
        showActions: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.refreshProfile(),
          color: AppColors.primaryColor,
          backgroundColor: Colors.black,
          child: Obx(() {
            if (controller.isLoading.value &&
                controller.userProfile.value == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- HEADER PROFILE CARD ---
                  Container(
                    width: 105.w,
                    height: 105.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(55.w),
                      child: controller.profilePicture.value.isNotEmpty
                          ? Image.network(
                              controller.profilePicture.value,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              AppImages.sadat_image,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // --- USER NAME ---
                  Text(
                    controller.fullName.value +
                        (controller.nickName.value.isNotEmpty
                            ? ' (${controller.nickName.value})'
                            : ''),
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFEDB9B), // Soft peach-yellow
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),

                  // --- BADGES FROM API ---
                  Obx(() {
                    final badges = controller.userProfile.value?.badges ?? [];
                    if (badges.isEmpty) return const SizedBox.shrink();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          alignment: WrapAlignment.center,
                          children: badges.map((b) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27272A),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: const Color(0xFF3F3F46),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: AppColors.primaryColor,
                                    size: 11.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    b,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFD5C4AB),
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    );
                  }),
                  SizedBox(height: 14.h),

                  // --- EKKALI PREMIUM SUBSCRIPTION BANNER (COMMENTED OUT) ---
                  /*
                  GestureDetector(
                    onTap: () => Get.toNamed(Routes.subscriptionView),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2A1C08),
                            Color(0xFF191307),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.black,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Ekkali Premium',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFFEDB9B),
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        '\$29/YR',
                                        style: GoogleFonts.inter(
                                          color: Colors.black,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '0% Fee • VIP Badge • Priority Jobs',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFD5C4AB),
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFFFEDB9B),
                            size: 16.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  */

                  // --- CATEGORY 1: ACCOUNT & CHAUFFEUR DETAILS ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Account & Chauffeur Details',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD5C4AB),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  Material(
                    color: const Color(0xFF1A1A1A),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: const BorderSide(
                        color: Color(0xFF2C2C2C),
                        width: 0.98,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.workspace_premium_outlined,
                          title: "Ekkali Premium Subscription",
                          subtitle: "Yearly plan (\$29/Yr) & benefits",
                          iconColor: const Color(0xFFFEDB9B),
                          titleColor: const Color(0xFFFEDB9B),
                          onTap: () {
                            Get.toNamed(Routes.subscriptionView);
                          },
                        ),
                        _buildTileDivider(),
                        _buildSettingTile(
                          icon: Icons.person_outline_rounded,
                          title: "My information",
                          subtitle: "Manage email, phone, and company",
                          onTap: () {
                            Get.to(() => const PersonalInformationView());
                          },
                        ),
                        _buildTileDivider(),
                        _buildSettingTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: "My Payment Methods",
                          subtitle: "Manage Zelle, Venmo, Cash App & Card",
                          onTap: () {
                            Get.to(() => const PaymentInformationView());
                          },
                        ),
                        _buildTileDivider(),
                        _buildSettingTile(
                          icon: Icons.directions_car_outlined,
                          title: "My Vehicles",
                          subtitle: "Manage and select active vehicles",
                          onTap: () {
                            Get.toNamed(Routes.allVehicleView);
                          },
                        ),
                        _buildTileDivider(),
                        _buildSettingTile(
                          icon: Icons.document_scanner_outlined,
                          title: "My Personal Documents",
                          subtitle: "License and verification documents",
                          onTap: () {
                            Get.toNamed(Routes.personalDocumentView);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // --- CATEGORY 2: PREFERENCES & SUPPORT ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Preferences & Support',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD5C4AB),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  Material(
                    color: const Color(0xFF1A1A1A),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: const BorderSide(
                        color: Color(0xFF2C2C2C),
                        width: 0.98,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.star_outline_rounded,
                          title: "Ratings & Feedback",
                          onTap: () => Get.toNamed(Routes.ratingsFeedbackView),
                        ),
                        Obx(
                          () => Column(
                            children: controller.legalPages.map((legal) {
                              return Column(
                                children: [
                                  _buildTileDivider(),
                                  _buildSettingTile(
                                    icon: Icons.description_outlined,
                                    title: legal['title'] ?? "",
                                    onTap: () => Get.toNamed(
                                      Routes.termPolicyView,
                                      arguments: {"slug": legal['slug']},
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        _buildTileDivider(),
                        _buildSettingTile(
                          icon: Icons.headset_mic_outlined,
                          title: "Support and Report",
                          onTap: () => showContactSupportBottomSheet(),
                        ),
                        _buildTileDivider(),
                        _buildSettingTile(
                          icon: Icons.settings_outlined,
                          title: "Settings",
                          subtitle: "Security & Account settings",
                          onTap: () => Get.toNamed(Routes.settingsView),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // --- ACTIONS: LOG OUT ---
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF261214),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () {
                          Get.bottomSheet(
                            const LogoutBottomSheet(),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.logout_rounded,
                                  color: const Color(0xFFEF4444),
                                  size: 18.sp,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                "Log Out",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFEF4444),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- REUSABLE UI BUILDERS ---

  Widget _buildTileDivider() {
    return const Divider(color: Color(0xFF2C2C2C), thickness: 1, height: 1);
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white70,
          size: 19.sp,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: titleColor ?? Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                color: const Color(0xFF71717A),
                fontSize: 11.sp,
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: const Color(0xFF71717A),
        size: 14.sp,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      onTap: onTap,
    );
  }
}
