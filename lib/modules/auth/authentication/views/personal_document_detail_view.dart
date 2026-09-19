import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/personal_document_controller.dart';

class PersonalDocumentDetailView extends StatefulWidget {
  final String? documentType;

  const PersonalDocumentDetailView({super.key, this.documentType});

  @override
  State<PersonalDocumentDetailView> createState() =>
      _PersonalDocumentDetailViewState();
}

class _PersonalDocumentDetailViewState
    extends State<PersonalDocumentDetailView> {
  late final PersonalDocumentController controller;
  late final String docType;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<PersonalDocumentController>()
        ? Get.find<PersonalDocumentController>()
        : Get.put(PersonalDocumentController());

    final args = Get.arguments;
    if (widget.documentType != null && widget.documentType!.isNotEmpty) {
      docType = widget.documentType!;
    } else if (args is Map && args['documentType'] != null) {
      docType = args['documentType'].toString();
    } else if (args is String && args.isNotEmpty) {
      docType = args;
    } else {
      docType = 'DRIVING_LICENSE';
    }
  }

  bool get isDL => docType == 'DRIVING_LICENSE';
  bool get isHL => docType == 'HACK_LICENSE';
  bool get isLP => docType == 'LOCAL_PERMIT';

  String get docTitle => isDL
      ? "Driving License"
      : isHL
      ? "Hack License"
      : "Local Permit";

  IconData get docIcon => isDL
      ? Icons.badge_outlined
      : isHL
      ? Icons.verified_user_outlined
      : Icons.location_city_outlined;

  RxnString get docIdRx => isDL
      ? controller.drivingLicenseId
      : isHL
      ? controller.hackLicenseId
      : controller.localPermitId;

  RxnString get statusRx => isDL
      ? controller.drivingLicenseStatus
      : isHL
      ? controller.hackLicenseStatus
      : controller.localPermitStatus;

  RxnString get urlRx => isDL
      ? controller.drivingLicenseUrl
      : isHL
      ? controller.hackLicenseUrl
      : controller.localPermitUrl;

  Rx<File?> get fileRx => isDL
      ? controller.drivingLicenseFile
      : isHL
      ? controller.hackLicenseFile
      : controller.localPermitFile;

  TextEditingController get expireController => isDL
      ? controller.drivingLicenseExpireController
      : isHL
      ? controller.hackLicenseExpireController
      : controller.localPermitExpireController;

  RxString get expiryRx => isDL
      ? controller.drivingLicenseExpiry
      : isHL
      ? controller.hackLicenseExpiry
      : controller.localPermitExpiry;

  RxBool get isUpdatingRx => isDL
      ? controller.isUpdatingDrivingLicense
      : isHL
      ? controller.isUpdatingHackLicense
      : controller.isUpdatingLocalPermit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomSubAppBar(title: "$docTitle Details"),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: const Color(0xFF1A1A1E),
        onRefresh: () => controller.fetchDocuments(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          child: Obx(() {
            final currentStatus = statusRx.value;
            final currentUrl = urlRx.value;
            final currentFile = fileRx.value;
            final isUpdating = isUpdatingRx.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Single Unified Document Header Card
                _buildHeaderCard(currentStatus),
                SizedBox(height: 14.h),

                // 2. Document Attachment & Preview Card
                _buildDocumentPreviewCard(
                  context: context,
                  file: currentFile,
                  url: currentUrl,
                ),
                SizedBox(height: 14.h),

                // 3. Expiration Date Card
                _buildExpiryDateCard(context),
                SizedBox(height: 24.h),

                // 4. Update/Upload Action Button
                CustomButton(
                  text: isUpdating
                      ? "Saving..."
                      : (docIdRx.value != null && docIdRx.value!.isNotEmpty
                          ? "Save & Update Document"
                          : "Upload & Save Document"),
                  loading: isUpdating,
                  onPressed: () async {
                    await controller.updateSingleDocument(docType);
                  },
                ),
                SizedBox(height: 16.h),

                // Helper Note
                Center(
                  child: Text(
                    "All document uploads and updates are verified for transport compliance.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11.5.sp,
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Unified Header Card (No duplicate cards)
  Widget _buildHeaderCard(String? status) {
    final normalized = (status ?? '').toUpperCase();
    final isApproved = normalized == 'APPROVED';
    final isPending =
        normalized.contains('PENDING') ||
        normalized.contains('SCAN') ||
        normalized == 'UNDER_REVIEW';
    final isRejected =
        normalized.contains('REJECT') || normalized.contains('DECLIN');

    String subtitle;
    Color subtitleColor;

    if (isApproved) {
      subtitle = "Verified & Active";
      subtitleColor = const Color(0xFF34D399);
    } else if (isPending) {
      subtitle = "Under Verification Review";
      subtitleColor = const Color(0xFFFBBF24);
    } else if (isRejected) {
      subtitle = "Action Required (Rejected)";
      subtitleColor = const Color(0xFFF87171);
    } else if (status == null || status.isEmpty) {
      subtitle = "Document Not Uploaded Yet";
      subtitleColor = const Color(0xFF94A3B8);
    } else {
      subtitle = "Official Credential";
      subtitleColor = const Color(0xFF94A3B8);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF222228)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C22),
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(color: const Color(0xFF282832)),
            ),
            child: Icon(docIcon, color: Colors.white, size: 21.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docTitle,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: subtitleColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(status),
        ],
      ),
    );
  }

  /// Document Preview & File Selection Card
  Widget _buildDocumentPreviewCard({
    required BuildContext context,
    required File? file,
    required String? url,
  }) {
    final hasFile = file != null;
    final hasUrl = url != null && url.isNotEmpty;
    final isPdf =
        (hasFile && file.path.toLowerCase().endsWith('.pdf')) ||
        (hasUrl && url.toLowerCase().contains('.pdf'));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF222228)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Document File",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasFile || hasUrl)
                GestureDetector(
                  onTap: () {
                    controller.previewImage(
                      context,
                      fileRx,
                      urlRx,
                      title: "$docTitle Preview",
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C22),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: const Color(0xFF282832)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: const Color(0xFFE2E8F0),
                          size: 13.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          "Preview",
                          style: GoogleFonts.inter(
                            color: const Color(0xFFE2E8F0),
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Preview Container
          if (hasFile || hasUrl) ...[
            Container(
              width: double.infinity,
              height: 140.h,
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C0E),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFF202026)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isPdf)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: const Color(0xFFEF4444),
                            size: 36.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            hasFile
                                ? controller.getFileName(fileRx)
                                : "PDF Document Attached",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            "Tap 'Preview' to open document",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 10.5.sp,
                            ),
                          ),
                        ],
                      )
                    else if (hasFile)
                      Image.file(
                        file,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    else
                      Image.network(
                        url!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: const Color(0xFF64748B),
                            size: 30.sp,
                          ),
                        ),
                      ),

                    // Tap to zoom
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            controller.previewImage(
                              context,
                              fileRx,
                              urlRx,
                              title: "$docTitle Preview",
                            );
                          },
                        ),
                      ),
                    ),

                    if (hasFile)
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: GestureDetector(
                          onTap: () => fileRx.value = null,
                          child: Container(
                            padding: EdgeInsets.all(5.w),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 13.sp,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ] else ...[
            GestureDetector(
              onTap: () => controller.pickFromFile(context, fileRx),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 22.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0C0E),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFF202026)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: const Color(0xFF64748B),
                      size: 28.sp,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "No document file attached",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Actions: Camera & Upload File buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.pickFromCamera(fileRx),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    minimumSize: Size(0, 42.h),
                    backgroundColor: const Color(0xFF1C1C22),
                    side: const BorderSide(color: Color(0xFF282832)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 15.sp,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          "Camera",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.pickFromFile(context, fileRx),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    minimumSize: Size(0, 42.h),
                    backgroundColor: const Color(0xFF1C1C22),
                    side: const BorderSide(color: Color(0xFF282832)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.file_upload_outlined,
                        color: Colors.white,
                        size: 15.sp,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          hasFile || hasUrl ? "Replace File" : "Upload File",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Expiry Date Selection Card
  Widget _buildExpiryDateCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF222228)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Expiration Date",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Set the official expiry date as printed on your credential.",
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.5.sp,
            ),
          ),
          SizedBox(height: 12.h),

          GestureDetector(
            onTap: () => controller.selectDate(
              context,
              expireController,
              expiryRx: expiryRx,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C0E),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFF202026)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    final date = expiryRx.value.isNotEmpty
                        ? expiryRx.value
                        : expireController.text.trim();
                    final hasDate = date.isNotEmpty;
                    return Text(
                      hasDate ? date : "YYYY-MM-DD",
                      style: GoogleFonts.inter(
                        color: hasDate ? Colors.white : const Color(0xFF64748B),
                        fontSize: 13.sp,
                        fontWeight: hasDate ? FontWeight.w500 : FontWeight.w400,
                      ),
                    );
                  }),
                  Icon(
                    Icons.calendar_today_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
