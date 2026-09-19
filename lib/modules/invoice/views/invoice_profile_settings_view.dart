import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import '../controllers/invoice_controller.dart';

class InvoiceProfileSettingsView extends GetView<InvoiceController> {
  const InvoiceProfileSettingsView({super.key});

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
              'Profile Setting',
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
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryColor,
                backgroundColor: Colors.black,
                onRefresh: () => controller.fetchInvoiceProfileFromApi(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- BUSINESS LOGO CARD ---
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => controller.pickBusinessLogo(),
                            child: Container(
                              width: 160.w,
                              height: 120.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: const Color(0xFF27272A), width: 1.5),
                              ),
                              child: controller.businessLogoPath.value != null &&
                                      controller.businessLogoPath.value!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14.r),
                                      child: (controller.businessLogoPath.value!
                                                  .startsWith('http://') ||
                                              controller.businessLogoPath.value!
                                                  .startsWith('https://'))
                                          ? Image.network(
                                              controller.businessLogoPath.value!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ),
                                            )
                                          : Image.file(
                                              File(controller.businessLogoPath.value!),
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.directions_car_filled_outlined,
                                            color: const Color(0xFFFEDB9B), // Soft peach-yellow
                                            size: 32.sp,
                                          ),
                                          SizedBox(height: 6.h),
                                          Text(
                                            'KALI RIDE',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          Text(
                                            'LLC',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFFD5C4AB),
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          GestureDetector(
                            onTap: () => controller.pickBusinessLogo(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: const Color(0xFFD5C4AB),
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'TAP TO CHANGE',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFD5C4AB),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // --- PROFILE HEADER ---
                    Text(
                      'PROFILE',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD5C4AB),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      controller.savedBusinessName.value,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFEDB9B), // Soft peach-yellow
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // --- GENERAL INFORMATION ---
                    Text(
                      'General information',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Business Name Card
                    _buildProfileInputField(
                      title: 'Business name',
                      controller: controller.businessNameController,
                      hint: 'Enter Business Name',
                      maxLength: 30,
                    ),
                    SizedBox(height: 16.h),

                    // Email Card
                    _buildProfileInputField(
                      title: 'Email (optional)',
                      controller: controller.businessEmailController,
                      hint: 'Enter Business Email',
                      maxLength: 30,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16.h),

                    // Phone Number Card
                    _buildProfileInputField(
                      title: 'Phone number (optional)',
                      controller: controller.businessPhoneController,
                      hint: 'Enter Phone Number',
                      maxLength: 30,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16.h),

                    // Website Card
                    _buildProfileInputField(
                      title: 'Website (optional)',
                      controller: controller.businessWebsiteController,
                      hint: 'Enter Business Website',
                      maxLength: 40,
                      keyboardType: TextInputType.url,
                    ),
                    SizedBox(height: 16.h),

                    // Address Card
                    _buildProfileInputField(
                      title: 'Address (optional)',
                      controller: controller.businessAddressController,
                      hint: 'Enter business address',
                      maxLength: 30,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
            
            // --- SAVE BUTTON ---
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                ),
              ),
              child: CustomButton(
                text: 'Save',
                loading: controller.isLoading.value,
                onPressed: () => controller.saveProfileSettings(),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProfileInputField({
    required String title,
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // Dark container background
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF27272A), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: const Color(0xFFD5C4AB),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '$maxLength Symbols',
                style: GoogleFonts.inter(
                  color: const Color(0xFF52525B),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF3F3F46),
                fontSize: 15.sp,
              ),
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
