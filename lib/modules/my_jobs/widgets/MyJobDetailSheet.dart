// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';

class MyJobDetailSheet extends StatelessWidget {
  final String title;
  final String bookingNo;
  final String dateTimeStr;
  final String pickupLocation;
  final String? pickupNotes;
  final String dropoffLocation;
  final String? dropoffNotes;
  final String passengerName;
  final String driverName;
  final String? driverId;
  final String? driverImage;
  final double? driverRating;
  final String vehicleInfo;
  final String vehicleType;
  final String? paymentType;
  final String? amount;
  final String? flightNumber;
  final String? specialInstructions;
  final String status;
  final bool isReviewedByCreator;
  final bool hasApplicant;
  final String? actionButtonText;
  final VoidCallback? onActionButtonPressed;
  final VoidCallback? onAcceptPressed;
  final VoidCallback? onRejectPressed;
  final VoidCallback? onChatPressed;
  final VoidCallback? onReviewPressed;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onDriverPressed;

  const MyJobDetailSheet({
    super.key,
    this.title = "Created Job Details",
    required this.bookingNo,
    required this.dateTimeStr,
    required this.pickupLocation,
    this.pickupNotes,
    required this.dropoffLocation,
    this.dropoffNotes,
    required this.passengerName,
    required this.driverName,
    this.driverId,
    this.driverImage,
    this.driverRating,
    required this.vehicleInfo,
    required this.vehicleType,
    this.paymentType,
    this.amount,
    this.flightNumber,
    this.specialInstructions,
    required this.status,
    this.isReviewedByCreator = false,
    this.hasApplicant = false,
    this.actionButtonText,
    this.onActionButtonPressed,
    this.onAcceptPressed,
    this.onRejectPressed,
    this.onChatPressed,
    this.onReviewPressed,
    this.onEditPressed,
    this.onDeletePressed,
    this.onDriverPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String currentStatus = status.toUpperCase();
    final bool canEdit =
        (currentStatus == 'PENDING') && (onEditPressed != null);
    final bool canDelete =
        (currentStatus == 'PENDING' || currentStatus == 'CANCELLED') &&
        (onDeletePressed != null);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: const Color(0xFF24242A), width: 1),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle Bar
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF33333E),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Header Row: Title, Booking No & Actions (Edit/Delete/Close)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.all(6.r),
                        constraints: const BoxConstraints(),
                        onPressed: onEditPressed,
                        icon: SvgPicture.asset(
                          AppIcons.edit_icon_myjob,
                          width: 18.sp,
                          height: 18.sp,
                          colorFilter: const ColorFilter.mode(
                            Colors.white70,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                    ],
                    if (canDelete) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.all(6.r),
                        constraints: const BoxConstraints(),
                        onPressed: onDeletePressed,
                        icon: SvgPicture.asset(
                          AppIcons.deletemyjob_icon,
                          width: 18.sp,
                          height: 18.sp,
                          colorFilter: const ColorFilter.mode(
                            Colors.redAccent,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                    ],
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.all(6.r),
                      constraints: const BoxConstraints(),
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey[400],
                        size: 22.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Section 1: Route & Timeline Info
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DateTime & Price Row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white70,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        dateTimeStr,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (amount != null && amount!.isNotEmpty) ...[
                        Text(
                          "\$$amount",
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFEDB9B),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Divider(color: const Color(0xFF22222A), height: 1.h),
                  SizedBox(height: 14.h),

                  // Route Timeline
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12.r,
                              height: 12.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: 2.w,
                                color: const Color(0xFF2E2E38),
                              ),
                            ),
                            Container(
                              width: 12.r,
                              height: 12.r,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFEDB9B),
                              ),
                            ),
                            SizedBox(height: 4.h),
                          ],
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "PICKUP",
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    pickupLocation,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DROPOFF",
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    dropoffLocation,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Section 2: Driver & Vehicle Info / Applicant Card
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (onDriverPressed != null) {
                              onDriverPressed!();
                            } else if (driverId != null &&
                                driverId!.isNotEmpty) {
                              final preferredController =
                                  Get.isRegistered<PreferredDriversController>()
                                      ? Get.find<PreferredDriversController>()
                                      : Get.put(PreferredDriversController());

                              preferredController.openChauffeurProfile(
                                userId: driverId!,
                                name: driverName,
                                imageUrl: driverImage ?? '',
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1C1C1F),
                                  border: Border.all(
                                    color: const Color(0xFF2A2A32),
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: (driverImage != null &&
                                          driverImage!.trim().isNotEmpty)
                                      ? (driverImage!.startsWith('http')
                                          ? Image.network(
                                              driverImage!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.person_outline,
                                                color: const Color(0xFFFEDB9B),
                                                size: 20.sp,
                                              ),
                                            )
                                          : Image.asset(
                                              driverImage!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.person_outline,
                                                color: const Color(0xFFFEDB9B),
                                                size: 20.sp,
                                              ),
                                            ))
                                      : Icon(
                                          status == 'PENDING'
                                              ? Icons.person_outline
                                              : Icons.directions_car_outlined,
                                          color: const Color(0xFFFEDB9B),
                                          size: 20.sp,
                                        ),
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
                                          "CHAUFFEUR",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF94A3B8),
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        if ((driverId != null &&
                                                driverId!.isNotEmpty) ||
                                            onDriverPressed != null) ...[
                                          SizedBox(width: 4.w),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: const Color(0xFF94A3B8),
                                            size: 8.sp,
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      driverName.isNotEmpty
                                          ? driverName
                                          : "Not Assigned",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (driverRating != null &&
                                        driverRating! > 0) ...[
                                      SizedBox(height: 2.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: const Color(0xFFFEDB9B),
                                            size: 12.sp,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            driverRating!.toStringAsFixed(1),
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 11.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (onChatPressed != null &&
                          (currentStatus != 'PENDING' || hasApplicant)) ...[
                        SizedBox(width: 8.w),
                        InkWell(
                          onTap: () {
                            Get.back();
                            onChatPressed!();
                          },
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E26),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: const Color(0xFF333342),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: const Color(0xFFFEDB9B),
                                  size: 16.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Chat",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFEDB9B),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Section 3: Extra Info (Payment, Flight & Instructions)
            SizedBox(height: 12.h),
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Payment Method",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          (paymentType != null && paymentType!.isNotEmpty)
                              ? paymentType!
                              : "Credit Card on File",
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Flight Number",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          (flightNumber != null && flightNumber!.isNotEmpty)
                              ? flightNumber!
                              : "N/A",
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    "SPECIAL INSTRUCTIONS",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090B14),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFF1B2033)),
                    ),
                    child: Text(
                      (specialInstructions != null &&
                              specialInstructions!.isNotEmpty)
                          ? specialInstructions!
                          : "No special instructions provided.",
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.sp,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section 4: Action Buttons (Accept/Reject for PENDING with Applicant, Ride Progress for ASSIGNED, Review for COMPLETED)
            if (status == 'PENDING') ...[
              if (hasApplicant && onAcceptPressed != null) ...[
                SizedBox(height: 20.h),
                Row(
                  children: [
                    if (onRejectPressed != null) ...[
                      Expanded(
                        child: CustomButton(
                          text: "Decline",
                          backgroundColor: Colors.transparent,
                          textColor: Colors.redAccent,
                          borderColor: Colors.redAccent,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          onPressed: () {
                            Get.back();
                            onRejectPressed?.call();
                          },
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        text: "Accept",
                        icon: Icon(
                          Icons.check_circle_outline,
                          size: 18.sp,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          Get.back();
                          onAcceptPressed?.call();
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141416),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF24242A)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        color: const Color(0xFFFEDB9B),
                        size: 18.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          "Awaiting Chauffeur Application — You will be able to review and approve drivers once they apply.",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12.sp,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else if (status == 'ASSIGNED') ...[
              SizedBox(height: 20.h),
              CustomButton(
                text: "View Ride Progress",
                // backgroundColor: const Color(0xFFD08700),
                // textColor: Colors.black,
                // fontSize: 14.sp,
                // fontWeight: FontWeight.bold,
                icon: Icon(
                  Icons.navigation_outlined,
                  size: 18.sp,
                  color: Colors.black,
                ),
                onPressed: () {
                  Get.back();
                  onActionButtonPressed?.call();
                },
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ] else if (currentStatus == 'COMPLETED' || currentStatus == 'FINISHED') ...[
              if (!isReviewedByCreator) ...[
                SizedBox(height: 20.h),
                CustomButton(
                  text: "Rate & Review",
                  backgroundColor: AppColors.primaryColor,
                  textColor: Colors.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  icon: Icon(
                    Icons.star_outline_rounded,
                    size: 18.sp,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Get.back();
                    onReviewPressed?.call();
                  },
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ] else ...[
                SizedBox(height: 20.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Review Submitted",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF10B981),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else if (actionButtonText != null &&
                onActionButtonPressed != null) ...[
              SizedBox(height: 20.h),
              CustomButton(
                text: actionButtonText!,
                backgroundColor: const Color(0xFFD08700),
                textColor: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                onPressed: () {
                  Get.back();
                  onActionButtonPressed!();
                },
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF24242A), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
