import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/data/models/my_rides_model.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';

class RideDetailSheet extends StatelessWidget {
  final RideData ride;
  final bool isPast;
  final String? dateHeader;
  final VoidCallback? onReviewPressed;

  const RideDetailSheet({
    super.key,
    required this.ride,
    required this.isPast,
    this.dateHeader,
    this.onReviewPressed,
  });

  String _formatDateTime(RideData r) {
    if (r.asap) {
      String datePart = "Today";
      if (r.createdAt != null && r.createdAt!.isNotEmpty) {
        try {
          final dt = DateTime.parse(r.createdAt!);
          datePart = DateFormat("MMM dd, yyyy").format(dt);
        } catch (_) {}
      }
      return "$datePart • ASAP";
    }

    String datePart = "";
    if (r.date != null && r.date!.isNotEmpty) {
      try {
        final dt = DateTime.parse(r.date!);
        datePart = DateFormat("MMM dd, yyyy").format(dt);
      } catch (_) {
        datePart = r.date!;
      }
    } else {
      datePart = dateHeader ?? "Today";
    }

    String timePart = "";
    if (r.time != null && r.time!.isNotEmpty) {
      try {
        if (r.time!.contains(":")) {
          final parts = r.time!.split(":");
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final now = DateTime.now();
          final timeDt = DateTime(now.year, now.month, now.day, hour, minute);
          timePart = DateFormat("hh:mm a").format(timeDt);
        } else {
          timePart = r.time!;
        }
      } catch (_) {
        timePart = r.time!;
      }
    }

    if (timePart.isNotEmpty) {
      return "$datePart • $timePart";
    }
    return datePart;
  }

  String _getPosterName(RideData r) {
    if (r.name != null && r.name!.trim().isNotEmpty) return r.name!.trim();
    if (r.createdBy?.name != null && r.createdBy!.name.trim().isNotEmpty) {
      return r.createdBy!.name.trim();
    }
    if (r.companyName != null && r.companyName!.trim().isNotEmpty) {
      return r.companyName!.trim();
    }
    return "Job Poster";
  }

  String _getPosterImage(RideData r) {
    if (r.profilePicture != null && r.profilePicture!.trim().isNotEmpty) {
      return r.profilePicture!.trim();
    }
    if (r.createdBy?.profilePicture != null &&
        r.createdBy!.profilePicture.trim().isNotEmpty) {
      return r.createdBy!.profilePicture.trim();
    }
    return "";
  }

  String _getPosterId(RideData r) {
    return r.jobCreatorId ?? r.createdBy?.id ?? "";
  }

  String _getVehicleInfo(RideData r) {
    final driver = r.assignedTo ?? r.applicant?.driver ?? r.createdBy;
    if (driver?.vehicles != null && driver!.vehicles!.isNotEmpty) {
      final v = driver.vehicles!.first;
      return "${v.make} ${v.model}, ${v.colorOutside}";
    }
    return r.vehicleType.isNotEmpty ? r.vehicleType : "Sedan";
  }

  void _openChat(RideData r) async {
    final String participantId = _getPosterId(r);
    if (participantId.isNotEmpty) {
      try {
        final socketRepo = Get.isRegistered<SocketRepository>()
            ? Get.find<SocketRepository>()
            : Get.put(SocketRepository(apiClient: Get.find<ApiClient>()));

        final chat = await socketRepo.createChat(participantId);
        if (chat != null) {
          Get.back();
          Get.toNamed(Routes.chatDetailView, arguments: chat);
          return;
        }
      } catch (e) {
        debugPrint("Error opening chat: $e");
      }
    }

    Helpers.showCustomSnackBar(
      "Unable to start chat session with user right now.",
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isPast ? "Completed Ride" : "Upcoming Ride Details";
    final dateTimeStr = _formatDateTime(ride);
    final amountStr =
        ride.paymentAmount != null ? "${ride.paymentAmount}" : "0.00";
    final posterName = _getPosterName(ride);
    final posterImage = _getPosterImage(ride);
    final posterId = _getPosterId(ride);
    final vehicleInfo = _getVehicleInfo(ride);
    final paymentTypeStr = ride.paymentType?.isNotEmpty == true
        ? ride.paymentType!
        : "Credit Card on File";
    final flightNumberStr =
        ride.flightNumber?.isNotEmpty == true ? ride.flightNumber! : "N/A";
    final instructions = ride.instruction ?? "";

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

            // Header Row: Title & Close Button
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
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey[400],
                    size: 22.sp,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Section 1: Route & Timeline Info
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DateTime & Amount Row
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
                      if (amountStr.isNotEmpty) ...[
                        Text(
                          "\$$amountStr",
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
                                    ride.pickupLocation,
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
                                    ride.dropoffLocation,
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

            // Section 2: Job Poster & Chauffeur Info
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
                            final preferredController =
                                Get.isRegistered<PreferredDriversController>()
                                ? Get.find<PreferredDriversController>()
                                : Get.put(PreferredDriversController());

                            preferredController.openChauffeurProfile(
                              userId: posterId,
                              name: posterName,
                              imageUrl: posterImage,
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 38.r,
                                height: 38.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1C1C1F),
                                  border: Border.all(
                                    color: const Color(0xFF2A2A32),
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: posterImage.isNotEmpty
                                      ? (posterImage.startsWith('http')
                                          ? Image.network(
                                              posterImage,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.person_outline,
                                                color: Colors.white70,
                                                size: 20.sp,
                                              ),
                                            )
                                          : Image.asset(
                                              posterImage,
                                              fit: BoxFit.cover,
                                            ))
                                      : Icon(
                                          Icons.person_outline,
                                          color: Colors.white70,
                                          size: 20.sp,
                                        ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "JOB POSTER",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      posterName,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isPast) ...[
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () => _openChat(ride),
                          child: Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD08700).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: const Color(0xFFD08700).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: const Color(0xFFFEDB9B),
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Divider(color: const Color(0xFF22222A), height: 1.h),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1F),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFF2A2A32),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.directions_car_outlined,
                          color: Colors.white70,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "VEHICLE",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              vehicleInfo.isNotEmpty ? vehicleInfo : "N/A",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
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
                      Text(
                        paymentTypeStr,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
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
                      Text(
                        flightNumberStr,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
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
                      instructions.isNotEmpty
                          ? instructions
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

            if (isPast) ...[
              if (ride.hasReview != true && ride.isReviewedByDriver != true) ...[
                SizedBox(height: 20.h),
                CustomButton(
                  text: "Rate & Review",
                  backgroundColor: AppColors.primaryColor,
                  textColor: Colors.black,
                  icon: Icon(
                    Icons.star_outline_rounded,
                    size: 18.sp,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Get.back();
                    if (onReviewPressed != null) {
                      onReviewPressed!();
                    } else {
                      Get.toNamed(Routes.rideCompletedView, arguments: ride);
                    }
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
            ] else ...[
              SizedBox(height: 20.h),
              CustomButton(
                text: "View Ride Progress",
                icon: Icon(
                  Icons.navigation_outlined,
                  size: 18.sp,
                  color: Colors.black,
                ),
                onPressed: () {
                  Get.back();
                  Get.toNamed(Routes.rideDetailsView, arguments: ride.id);
                },
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
