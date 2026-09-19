import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import '../controllers/meet_greet_controller.dart';

class MeetGreetView extends GetView<MeetGreetController> {
  const MeetGreetView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameTextController = TextEditingController();
    final TextEditingController subtitleTextController =
        TextEditingController();

    // Sync controllers with rx values
    nameTextController.text = controller.passengerName.value;
    subtitleTextController.text = controller.subtitleText.value;

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
              'Meet & Greet Sign',
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LIVE PREVIEW CARD ---
                    _buildSectionHeader('LIVE SIGN BOARD PREVIEW'),
                    SizedBox(height: 10.h),
                    _buildLivePreviewCard(),
                    SizedBox(height: 24.h),

                    // --- LOGO CONFIGURATION ---
                    _buildSectionHeader('LOGO CONFIGURATION'),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFF364153)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Enable Logo Header',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Obx(
                                () => Switch(
                                  value: controller.showCompanyLogo.value,
                                  activeThumbColor: const Color(0xFFD5C4AB),
                                  activeTrackColor: const Color(
                                    0xFFD5C4AB,
                                  ).withValues(alpha: 0.4),
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor: const Color(0xFF121212),
                                  onChanged: (v) async {
                                    if (v) {
                                      if (controller.customLogoPath.value ==
                                          null) {
                                        await controller.pickLogo();
                                        if (controller.customLogoPath.value ==
                                            null) {
                                          controller.showCompanyLogo.value =
                                              false;
                                          return;
                                        }
                                      }
                                    }
                                    controller.showCompanyLogo.value = v;
                                  },
                                ),
                              ),
                            ],
                          ),
                          Obx(() {
                            if (!controller.showCompanyLogo.value) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(
                                  color: Color(0xFF364153),
                                  height: 24,
                                ),
                                Text(
                                  'Custom Logo (Required)',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade400,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                controller.customLogoPath.value != null
                                    ? Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            child: Image.file(
                                              File(
                                                controller
                                                    .customLogoPath
                                                    .value!,
                                              ),
                                              width: 80.w,
                                              height: 60.h,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          SizedBox(width: 16.w),
                                          CustomButton(
                                            text: 'Remove',
                                            width: 110.w,
                                            onPressed: () {
                                              controller.customLogoPath.value =
                                                  null;
                                              controller.showCompanyLogo.value =
                                                  false;
                                            },
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                            // backgroundColor: const Color(0xFFFEDB9B),
                                            // textColor: Colors.black,
                                            // fontSize: 12.sp,
                                            // fontWeight: FontWeight.bold,
                                            // padding: EdgeInsets.symmetric(vertical: 10.h),
                                          ),
                                        ],
                                      )
                                    : GestureDetector(
                                        onTap: () => controller.pickLogo(),
                                        child: Container(
                                          width: double.infinity,
                                          height: 70.h,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF121212),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF364153),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.upload_file,
                                                color: const Color(0xFFD5C4AB),
                                                size: 20.sp,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                'Upload Custom Logo',
                                                style: GoogleFonts.inter(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // --- PASSENGER & SUBTITLE INPUTS ---
                    _buildSectionHeader('PASSENGER DETAILS'),
                    SizedBox(height: 12.h),

                    _buildInputField(
                      label: 'Passenger / Guest Name',
                      hintText: 'e.g. JOHN SMITH',
                      icon: Icons.person_outline,
                      controller: nameTextController,
                      onChanged: (val) {
                        controller.passengerName.value = val.trim().isEmpty
                            ? 'JOHN SMITH'
                            : val.trim().toUpperCase();
                      },
                    ),

                    SizedBox(height: 14.h),

                    _buildInputField(
                      label: 'Flight No. / Subtitle / Note',
                      hintText: 'e.g. FLIGHT BG-088',
                      icon: Icons.flight_land,
                      controller: subtitleTextController,
                      onChanged: (val) {
                        controller.subtitleText.value = val.trim();
                      },
                    ),

                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),

            // --- BOTTOM PRIMARY ACTION BUTTON ---
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
                ),
              ),
              child: CustomButton(
                text: 'SHOW PICKUP SIGN BOARD',

                icon: Icon(
                  Icons.fullscreen_rounded,
                  size: 24.sp,
                  color: Colors.black,
                ),

                onPressed: () {
                  if (controller.showCompanyLogo.value &&
                      controller.customLogoPath.value == null) {
                    Helpers.showCustomSnackBar(
                      'Please upload a custom logo or turn off the Logo Header switch.',
                      isError: true,
                    );
                    return;
                  }
                  Get.toNamed(Routes.meetGreetFullscreenView);
                },
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: const Color(0xFFD5C4AB),
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5.w,
      ),
    );
  }

  Widget _buildLivePreviewCard() {
    return Obx(() {
      final theme = controller.currentTheme;
      final pName = controller.passengerName.value;
      final pSubtitle = controller.subtitleText.value;

      return Container(
        width: double.infinity,
        height: 150.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: theme.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: theme.borderColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Center Main Content (Name & Subtitle)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        pName,
                        style: GoogleFonts.outfit(
                          color: theme.nameColor,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2.w,
                        ),
                      ),
                    ),
                    if (pSubtitle.isNotEmpty)
                      Text(
                        pSubtitle,
                        style: GoogleFonts.inter(
                          color: theme.subtitleColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Top-Left Logo Overlay
            if (controller.showCompanyLogo.value &&
                controller.customLogoPath.value != null)
              Positioned(
                top: 10.h,
                left: 12.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: Image.file(
                    File(controller.customLogoPath.value!),
                    width: 34.h,
                    height: 34.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade600,
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFFD5C4AB), size: 20.sp),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF364153)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFD5C4AB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFFD5C4AB),
          activeTrackColor: const Color(0xFFD5C4AB).withValues(alpha: 0.4),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: const Color(0xFF121212),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
