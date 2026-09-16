import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import '../controllers/personal_document_controller.dart';

class PersonalDocumentView extends StatelessWidget {
  PersonalDocumentView({super.key});

  final PersonalDocumentController controller =
      Get.isRegistered<PersonalDocumentController>()
          ? Get.find<PersonalDocumentController>()
          : Get.put(PersonalDocumentController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomSubAppBar(title: "Compliance Documents"),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryColor,
          backgroundColor: const Color(0xFF1A1A1E),
          onRefresh: () => controller.fetchDocuments(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            children: [
              // Clean Header Subtitle
              Padding(
                padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 20.h),
                child: Text(
                  "Manage and keep your official documents verified to stay eligible for ride requests.",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13.sp,
                    height: 1.45,
                  ),
                ),
              ),

              // Document Cards
              _buildDocumentCard(
                documentType: "DRIVING_LICENSE",
                title: "Driving License",
                icon: Icons.badge_outlined,
                statusRx: controller.drivingLicenseStatus,
                urlRx: controller.drivingLicenseUrl,
                expireController: controller.drivingLicenseExpireController,
                expiryRx: controller.drivingLicenseExpiry,
              ),

              _buildDocumentCard(
                documentType: "HACK_LICENSE",
                title: "Hack License",
                icon: Icons.verified_user_outlined,
                statusRx: controller.hackLicenseStatus,
                urlRx: controller.hackLicenseUrl,
                expireController: controller.hackLicenseExpireController,
                expiryRx: controller.hackLicenseExpiry,
              ),

              _buildDocumentCard(
                documentType: "LOCAL_PERMIT",
                title: "Local Permit",
                icon: Icons.location_city_outlined,
                statusRx: controller.localPermitStatus,
                urlRx: controller.localPermitUrl,
                expireController: controller.localPermitExpireController,
                expiryRx: controller.localPermitExpiry,
              ),

              SizedBox(height: 16.h),

              // Subtle bottom compliance guarantee note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 13.sp,
                    color: const Color(0xFF64748B),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Documents are encrypted & securely stored",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
            ],
          ),
        );
      }),
    );
  }

  /// Clean & Comfortable Document Card
  Widget _buildDocumentCard({
    required String documentType,
    required String title,
    required IconData icon,
    required RxnString statusRx,
    required RxnString urlRx,
    required TextEditingController expireController,
    required RxString expiryRx,
  }) {
    return Obx(() {
      final status = statusRx.value;
      final url = urlRx.value;
      final expiryDate = expiryRx.value.isNotEmpty
          ? expiryRx.value
          : expireController.text.trim();
      final hasUrl = url != null && url.isNotEmpty;

      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFF222228)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: () {
              Get.toNamed(
                Routes.personalDocumentDetailView,
                arguments: {"documentType": documentType},
              )?.then((_) => controller.fetchDocuments());
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
              child: Row(
                children: [
                  // Leading Neutral Icon Box
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C22),
                      borderRadius: BorderRadius.circular(11.r),
                      border: Border.all(color: const Color(0xFF282832)),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 21.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            _buildStatusBadge(status),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Text(
                              expiryDate.isNotEmpty
                                  ? "Expires $expiryDate"
                                  : "No expiry set",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 12.sp,
                              ),
                            ),
                            if (hasUrl) ...[
                              SizedBox(width: 6.w),
                              Text(
                                "•",
                                style: TextStyle(
                                  color: const Color(0xFF475569),
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                "Attached",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 10.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: const Color(0xFF64748B),
                    size: 13.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Clean, Soft Status Badge
  Widget _buildStatusBadge(String? status) {
    if (status == null || status.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color(0xFF334155), width: 0.8),
        ),
        child: Text(
          "Not Uploaded",
          style: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final normalized = status.toUpperCase();
    Color bg;
    Color border;
    Color textColor;
    String label;

    if (normalized == 'APPROVED') {
      bg = const Color(0xFF064E3B).withValues(alpha: 0.35);
      border = const Color(0xFF10B981).withValues(alpha: 0.3);
      textColor = const Color(0xFF34D399);
      label = "Approved";
    } else if (normalized.contains('PENDING') || normalized.contains('SCAN')) {
      bg = const Color(0xFF78350F).withValues(alpha: 0.35);
      border = const Color(0xFFF59E0B).withValues(alpha: 0.3);
      textColor = const Color(0xFFFBBF24);
      label = "Pending";
    } else if (normalized == 'REJECTED') {
      bg = const Color(0xFF7F1D1D).withValues(alpha: 0.35);
      border = const Color(0xFFEF4444).withValues(alpha: 0.3);
      textColor = const Color(0xFFF87171);
      label = "Rejected";
    } else {
      bg = const Color(0xFF1E293B);
      border = const Color(0xFF334155);
      textColor = const Color(0xFF94A3B8);
      label = normalized;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

