import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/data/models/my_rides_model.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class RideDetailSheet extends StatelessWidget {
  final RideData ride;
  final bool isPast;
  final String? dateHeader;
  final bool isCreatedByMe;
  final VoidCallback? onReviewPressed;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onAcceptApplicant;
  final VoidCallback? onRejectApplicant;
  final VoidCallback? onCancelJob;

  const RideDetailSheet({
    super.key,
    required this.ride,
    required this.isPast,
    this.dateHeader,
    this.isCreatedByMe = false,
    this.onReviewPressed,
    this.onEditPressed,
    this.onDeletePressed,
    this.onAcceptApplicant,
    this.onRejectApplicant,
    this.onCancelJob,
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
          final minute = int.parse(parts[1].split(" ")[0]);
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

  DriverData? _getChauffeur(RideData r) {
    return r.assignedTo ?? r.effectiveApplicantDriver;
  }

  String _getVehicleInfo(RideData r) {
    final driver = r.assignedTo ?? r.effectiveApplicantDriver ?? r.createdBy;
    if (driver?.vehicles != null && driver!.vehicles!.isNotEmpty) {
      final v = driver.vehicles!.first;
      return "${v.make} ${v.model}, ${v.colorOutside}";
    }
    return r.vehicleType.isNotEmpty ? r.vehicleType : "Sedan";
  }

  void _openChat(String participantId) async {
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
      "Unable to start chat session right now.",
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = (ride.status ?? 'PENDING').toUpperCase();
    final isPending = currentStatus == 'PENDING';
    final isCancelled = currentStatus == 'CANCELLED';
    final isAssigned =
        currentStatus == 'ASSIGNED' || currentStatus == 'IN PROGRESS';

    final String title = isCreatedByMe
        ? (isPast ? "Completed Job Details" : "Created Job Details")
        : (isPast ? "Completed Ride" : "Upcoming Ride Details");

    final dateTimeStr = _formatDateTime(ride);
    final amountStr = ride.paymentAmount != null
        ? "${ride.paymentAmount}"
        : "0.00";
    final posterName = _getPosterName(ride);
    final posterImage = _getPosterImage(ride);
    final posterId = _getPosterId(ride);
    final vehicleInfo = _getVehicleInfo(ride);
    final paymentTypeStr = ride.paymentType?.isNotEmpty == true
        ? ride.paymentType!
        : "Credit Card on File";
    final flightNumberStr = ride.flightNumber?.isNotEmpty == true
        ? ride.flightNumber!
        : "N/A";
    final instructions = ride.instruction ?? "";

    final chauffeur = _getChauffeur(ride);
    final hasApplicant = ride.hasApplicants;

    final bool canEdit =
        isCreatedByMe && isPending && !hasApplicant && onEditPressed != null;
    final bool canDelete =
        isCreatedByMe && (isPending || isCancelled) && onDeletePressed != null;

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

            // Header Row: Title, Action Icons (Edit / Delete) & Close Button
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
                        onPressed: () {
                          Get.back();
                          onEditPressed?.call();
                        },
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
                                    (ride.jobType?.toUpperCase() ==
                                                "BY THE HOUR" ||
                                            ride.dropoffLocation
                                                .toLowerCase()
                                                .contains("by the hour"))
                                        ? "SERVICE / DURATION"
                                        : "DROPOFF",
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    Helpers.formatDropoffDisplay(
                                      jobType: ride.jobType,
                                      dropoffLocation: ride.dropoffLocation,
                                      duration: ride.duration,
                                    ),
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

            // Section 2: Person & Vehicle Card
            _buildPersonSection(
              isCreatedByMe: isCreatedByMe,
              posterName: posterName,
              posterImage: posterImage,
              posterId: posterId,
              chauffeur: chauffeur,
              vehicleInfo: vehicleInfo,
              isPending: isPending,
              hasApplicant: hasApplicant,
              isPast: isPast,
            ),

            // Section 2.5: Passenger / Client Details
            _buildPassengerSection(
              ride: ride,
              isCreatedByMe: isCreatedByMe,
              isPending: isPending,
              chauffeur: chauffeur,
              isPast: isPast,
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

            // Section 4: Action Buttons based on Role & Status
            _buildBottomActions(
              isCreatedByMe: isCreatedByMe,
              isPending: isPending,
              isAssigned: isAssigned,
              isPast: isPast,
              hasApplicant: hasApplicant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonSection({
    required bool isCreatedByMe,
    required String posterName,
    required String posterImage,
    required String posterId,
    required DriverData? chauffeur,
    required String vehicleInfo,
    required bool isPending,
    required bool hasApplicant,
    required bool isPast,
  }) {
    if (isCreatedByMe) {
      // Creator Mode: Shows Chauffeur or Applicant
      final String personLabel = isPending
          ? (hasApplicant ? "APPLICANT CHAUFFEUR" : "CHAUFFEUR")
          : "ASSIGNED CHAUFFEUR";
      final String driverName = chauffeur?.name.isNotEmpty == true
          ? chauffeur!.name
          : (isPending
                ? (hasApplicant
                      ? "1 Applicant Available"
                      : "Awaiting Chauffeur")
                : "Not Assigned");
      final String driverImage = chauffeur?.profilePicture ?? '';
      final String driverId = chauffeur?.id ?? '';
      final double? driverRating = chauffeur?.averageRating;

      return _buildSectionCard(
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
                      if (driverId.isNotEmpty) {
                        final preferredController =
                            Get.isRegistered<PreferredDriversController>()
                            ? Get.find<PreferredDriversController>()
                            : Get.put(PreferredDriversController());

                        preferredController.openChauffeurProfile(
                          userId: driverId,
                          name: driverName,
                          imageUrl: driverImage,
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
                            child: driverImage.isNotEmpty
                                ? (driverImage.startsWith('http')
                                      ? Image.network(
                                          driverImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.person_outline,
                                            color: const Color(0xFFFEDB9B),
                                            size: 20.sp,
                                          ),
                                        )
                                      : Image.asset(
                                          driverImage,
                                          fit: BoxFit.cover,
                                        ))
                                : Icon(
                                    isPending
                                        ? Icons.hourglass_empty_rounded
                                        : Icons.person_outline,
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
                                    personLabel,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  if (driverId.isNotEmpty) ...[
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
                                driverName,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (driverRating != null && driverRating > 0) ...[
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
                                      driverRating.toStringAsFixed(1),
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
                if (driverId.isNotEmpty && !isPast) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _openChat(driverId),
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
      );
    } else {
      // Driver Mode: Shows Job Poster
      return _buildSectionCard(
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
                if (!isPast && posterId.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _openChat(posterId),
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
      );
    }
  }

  Widget _buildPassengerSection({
    required RideData ride,
    required bool isCreatedByMe,
    required bool isPending,
    required DriverData? chauffeur,
    required bool isPast,
  }) {
    // If not created by me and still pending (job applicant not accepted yet)
    if (!isCreatedByMe && isPending && chauffeur == null) {
      return Column(
        children: [
          SizedBox(height: 12.h),
          _buildSectionCard(
            child: Row(
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
                    Icons.lock_outline_rounded,
                    color: const Color(0xFFFEDB9B),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PASSENGER DETAILS",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Passenger details will be available once you are accepted for this ride.",
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final String pName = (ride.passengerName != null &&
            ride.passengerName!.trim().isNotEmpty)
        ? ride.passengerName!.trim()
        : "N/A";
    final String pPhone = (ride.passengerPhone != null &&
            ride.passengerPhone!.trim().isNotEmpty)
        ? ride.passengerPhone!.trim()
        : "N/A";

    return Column(
      children: [
        SizedBox(height: 12.h),
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PASSENGER DETAILS",
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pName,
                          style: GoogleFonts.inter(
                            color: pName != "N/A" ? Colors.white : Colors.white38,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          pPhone,
                          style: GoogleFonts.inter(
                            color: pPhone != "N/A"
                                ? const Color(0xFF94A3B8)
                                : Colors.white38,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pPhone != "N/A" && pPhone.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final phone = pPhone.trim();
                        final Uri launchUri = Uri(scheme: 'tel', path: phone);
                        if (await canLaunchUrl(launchUri)) {
                          await launchUrl(launchUri);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFD08700,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: const Color(
                              0xFFD08700,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.phone_outlined,
                          color: const Color(0xFFFEDB9B),
                          size: 20.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions({
    required bool isCreatedByMe,
    required bool isPending,
    required bool isAssigned,
    required bool isPast,
    required bool hasApplicant,
  }) {
    if (isPast) {
      final isReviewed = isCreatedByMe
          ? (ride.hasReview == true || ride.isReviewedByCreator == true)
          : (ride.hasReview == true || ride.isReviewedByDriver == true);

      if (!isReviewed) {
        return Padding(
          padding: EdgeInsets.only(top: 20.h),
          child: CustomButton(
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
        );
      } else {
        return Padding(
          padding: EdgeInsets.only(top: 20.h),
          child: Container(
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
        );
      }
    }

    if (isCreatedByMe) {
      if (isPending) {
        if (hasApplicant && onAcceptApplicant != null) {
          return Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: Row(
              children: [
                if (onRejectApplicant != null) ...[
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
                        onRejectApplicant?.call();
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
                      onAcceptApplicant?.call();
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
          );
        }
      } else if (isAssigned) {
        return Padding(
          padding: EdgeInsets.only(top: 20.h),
          child: CustomButton(
            text: "View Ride Progress",
            icon: Icon(
              Icons.navigation_outlined,
              size: 18.sp,
              color: Colors.black,
            ),
            onPressed: () {
              Get.back();
              Get.toNamed(
                Routes.myJobProgressDetailsView,
                arguments: ride.toJobData(),
              );
            },
          ),
        );
      }
    } else {
      // Driver view
      if (isPending) {
        return Padding(
          padding: EdgeInsets.only(top: 16.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                    "Application Under Review — You have applied for this ride. Waiting for the poster to approve your application.",
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
        );
      } else if (isAssigned) {
        return Padding(
          padding: EdgeInsets.only(top: 20.h),
          child: CustomButton(
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
        );
      }
    }

    return const SizedBox.shrink();
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
