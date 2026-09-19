import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/data/models/my_rides_model.dart';
import 'package:moeb_26/config/constants/image_paths.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/Custom_InfoBox.dart';
import 'package:moeb_26/core/widgets/custom_swipe_button.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';
import '../../../core/widgets/Custom_Card_Ditails.dart';
import '../controllers/my_ride_progress_details_controller.dart';

class MyRideProgressDetailsView extends StatelessWidget {
  MyRideProgressDetailsView({super.key});

  final MyRideProgressDetailsController controller = Get.put(
    MyRideProgressDetailsController(),
  );

  @override
  Widget build(BuildContext context) {
    // Get the ride data passed from the previous screen (could be Ride, UpcomingRideData, FinishRideData, Map, or String ID)
    final dynamic initialRide = Get.arguments;

    String rideId = "";
    if (initialRide is RideData) {
      rideId = initialRide.id;
    } else if (initialRide is Map) {
      rideId = initialRide['_id']?.toString() ??
          initialRide['id']?.toString() ??
          initialRide['bookingNo']?.toString() ??
          '';
    } else if (initialRide is String) {
      rideId = initialRide;
    }

    if (rideId.isNotEmpty) {
      // Set initial status to controller to prevent stale state
      String initialRideStatus = "PENDING";
      if (initialRide is RideData) {
        initialRideStatus = initialRide.rideStatus ?? initialRide.status ?? "PENDING";
      } else if (initialRide is Map) {
        initialRideStatus = initialRide['rideStatus'] ?? initialRide['status'] ?? "PENDING";
      }
      controller.setInitialStatus(rideId, initialRideStatus);
      controller.fetchJobDetails(rideId);
    }

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
              'Ride Details',
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
        top: false,
        bottom: true,
        child: Obx(() {
          if (controller.isLoading.value || controller.rideDetails.value == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 120.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primaryColor),
                    SizedBox(height: 16.h),
                    Text(
                      "Loading ride details...",
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA1A1A1),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final RideData rideObj = controller.rideDetails.value!;
          final data = _RideDetailsData.fromRide(rideObj);

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRideProgressTracker(),
                    SizedBox(height: 6.h),
                    _buildDriverSection(data),
                    SizedBox(height: 12.h),
                    _buildJobDetailsSection(data),
                    SizedBox(height: 12.h),
                    _buildSpecialInstructionsSection(data),
                    SizedBox(height: 12.h),
                    _buildActionButtonsSection(data, rideObj),
                    SizedBox(height: 20.h),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDriverSection(_RideDetailsData data) {
    final bool canOpenProfile = data.participantId.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: canOpenProfile
                ? () {
                    final preferredController =
                        Get.isRegistered<PreferredDriversController>()
                            ? Get.find<PreferredDriversController>()
                            : Get.put(PreferredDriversController());

                    preferredController.openChauffeurProfile(
                      userId: data.participantId,
                      name: data.posterName,
                      imageUrl: data.posterImage,
                    );
                  }
                : null,
            child: CircleAvatar(
              radius: 20.r,
              backgroundImage: data.posterImage.startsWith('http')
                  ? NetworkImage(data.posterImage)
                  : AssetImage(data.posterImage) as ImageProvider,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: canOpenProfile
                  ? () {
                      final preferredController =
                          Get.isRegistered<PreferredDriversController>()
                              ? Get.find<PreferredDriversController>()
                              : Get.put(PreferredDriversController());

                      preferredController.openChauffeurProfile(
                        userId: data.participantId,
                        name: data.posterName,
                        imageUrl: data.posterImage,
                      );
                    }
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.posterName,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Job Poster",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFFA1A1A1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              if (data.participantId.isNotEmpty) {
                try {
                  final chat = await Get.find<SocketRepository>().createChat(
                    data.participantId,
                  );
                  if (chat != null) {
                    Get.toNamed(Routes.chatDetailView, arguments: chat);
                  }
                } catch (e) {
                  Helpers.showCustomSnackBar(
                    "Failed to open chat",
                    isError: true,
                  );
                }
              }
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.primaryColor,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsSection(_RideDetailsData data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: CustomJobDetailsCard(
        pickupLocation: data.pickupLocation,
        dropoffLocation: data.dropoffLocation,
        flightNumber: data.flightNumber,
        dateTime: data.displayDateTime,
        vehicleType: data.vehicleType,
        jobPoster: data.posterName,
        company: data.posterCompany,
        payment: data.paymentType,
        amount: data.amount,
        backgroundColor: const Color(0xFF1A1A1A),
        borderColor: const Color(0xFF2C2C2C),
        labelColor: const Color(0xFFA1A1A1),
        valueColor: Colors.white,
        iconColor: Colors.white70,
        amountColor: const Color(0xFFFEDB9B),
      ),
    );
  }

  Widget _buildSpecialInstructionsSection(_RideDetailsData data) {
    if (data.instruction.trim().isEmpty) return const SizedBox.shrink();
    return CustomInfoBox(
      text: data.instruction,
      title: "Special Instructions",
      padding: EdgeInsets.symmetric(horizontal: 14.w),
    );
  }

  Widget _buildActionButtonsSection(_RideDetailsData data, dynamic ride) {
    return Obx(() {
      String status = controller.currentRideStatus.value;

      if (status == "POB") {
        // --- FINISH RIDE CUSTOM SWIPE SECTION ---
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: CustomSwipeButton(
            text: "Swipe to Finish Ride",
            onSwipeComplete: () {
              controller.updateStatus(data.id, "FINISHED", rideData: ride);
            },
          ),
        );
      }

      // --- STEP BUTTONS (On My Way, At Location, POB) ---
      String buttonText = "On My Way";
      String nextStatus = "ON THE WAY";
      bool isVisible = true;

      if (status == "ON THE WAY") {
        buttonText = "At the Location";
        nextStatus = "AT THE LOCATION";
      } else if (status == "AT THE LOCATION") {
        buttonText = "POB";
        nextStatus = "POB";
      } else if (status == "FINISHED" ||
          status == "COMPLETED" ||
          status == "CANCELLED") {
        isVisible = false;
      }

      if (!isVisible) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: controller.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              )
            : CustomButton(
                text: buttonText,
                backgroundColor: AppColors.primaryColor,
                textColor: Colors.black,
                onPressed: () => controller.updateStatus(data.id, nextStatus),
              ),
      );
    });
  }

  Widget _buildRideProgressTracker() {
    return Obx(() {
      String currentStatus = controller.currentRideStatus.value.toUpperCase();

      int activeStep = 0;
      if (currentStatus == "ON THE WAY") {
        activeStep = 1;
      } else if (currentStatus == "AT THE LOCATION") {
        activeStep = 2;
      } else if (currentStatus == "POB") {
        activeStep = 3;
      } else if (currentStatus == "FINISHED" || currentStatus == "COMPLETED") {
        activeStep = 4;
      }

      final steps = [
        {"label": "Assigned", "icon": Icons.assignment_turned_in_outlined},
        {"label": "On The Way", "icon": Icons.directions_car_outlined},
        {"label": "At Location", "icon": Icons.location_on_outlined},
        {"label": "POB", "icon": Icons.person_pin_circle_outlined},
        {"label": "Finished", "icon": Icons.task_alt},
      ];

      final isFinished = activeStep == 4;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ride Status Flow",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isFinished
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : AppColors.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isFinished
                          ? const Color(0xFF10B981)
                          : AppColors.primaryColor,
                    ),
                  ),
                  child: Text(
                    currentStatus.isEmpty ? "ASSIGNED" : currentStatus,
                    style: GoogleFonts.inter(
                      color: isFinished
                          ? const Color(0xFF10B981)
                          : AppColors.primaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: List.generate(steps.length, (index) {
                final isCompletedStep = index < activeStep;
                final isCurrentStep = index == activeStep;
                final isLastStep = index == steps.length - 1;

                final Color color = isCompletedStep
                    ? const Color(0xFF10B981)
                    : (isCurrentStep
                          ? AppColors.primaryColor
                          : const Color(0xFF52525B));

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompletedStep
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.15)
                                    : (isCurrentStep
                                          ? AppColors.primaryColor.withValues(
                                              alpha: 0.15,
                                            )
                                          : Colors.white.withValues(
                                              alpha: 0.05,
                                            )),
                                border: Border.all(
                                  color: color,
                                  width: isCurrentStep ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                isCompletedStep
                                    ? Icons.check
                                    : (steps[index]["icon"] as IconData),
                                color: color,
                                size: 16.sp,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              steps[index]["label"] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: isCurrentStep
                                    ? Colors.white
                                    : (isCompletedStep
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFA1A1A1)),
                                fontSize: 10.sp,
                                fontWeight: isCurrentStep
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLastStep)
                        Container(
                          width: 10.w,
                          height: 2.h,
                          margin: EdgeInsets.only(bottom: 20.h),
                          color: index < activeStep
                              ? const Color(0xFF10B981)
                              : Colors.white12,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

/// Helper model for cleanly extracting and parsing Ride data.
class _RideDetailsData {
  final String id;
  final String pickupLocation;
  final String dropoffLocation;
  final String vehicleType;
  final String paymentType;
  final String amount;
  final String rating;
  final String posterName;
  final String posterCompany;
  final String participantId;
  final String posterImage;
  final String vehicleInfo;
  final String vehicleNumber;
  final String flightNumber;
  final String instruction;
  final String displayDateTime;

  _RideDetailsData({
    required this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.vehicleType,
    required this.paymentType,
    required this.amount,
    required this.rating,
    required this.posterName,
    required this.posterCompany,
    required this.participantId,
    required this.posterImage,
    required this.vehicleInfo,
    required this.vehicleNumber,
    required this.flightNumber,
    required this.instruction,
    required this.displayDateTime,
  });

  factory _RideDetailsData.fromRide(dynamic ride) {
    String id = "";
    String pickupLocation = "N/A";
    String dropoffLocation = "N/A";
    String vehicleType = "N/A";
    String paymentType = "Credit Card on File";
    String amount = "N/A";
    String rating = "0.0";
    String posterName = "Unknown";
    String posterCompany = "Unknown";
    String participantId = "";
    String posterImage = AppImages.profile_image;
    String vehicleInfo = "N/A";
    String vehicleNumber = "N/A";
    String flightNumber = "N/A";
    String instruction = "N/A";
    String dateRaw = "";
    String timeRaw = "";

    String formatPayment(dynamic pType) {
      if (pType == null) return 'Credit Card on File';
      final str = pType.toString().trim().toUpperCase().replaceAll('_', ' ');
      if (str.isEmpty || str == 'NO COLLECT') {
        return 'Credit Card on File';
      }
      if (str == 'COLLECT') {
        return 'Collect Payment';
      }
      return pType.toString().replaceAll('_', ' ');
    }

    if (ride is RideData) {
      final r = ride;
      id = r.id;
      pickupLocation = r.pickupLocation;
      dropoffLocation = r.dropoffLocation;
      vehicleType = r.vehicleType;
      paymentType = formatPayment(r.paymentType);
      amount = r.paymentAmount != null ? "\$${r.paymentAmount}" : "N/A";
      flightNumber = r.flightNumber ?? "N/A";
      instruction = r.instruction ?? "N/A";

      final driver = r.createdBy ?? r.assignedTo ?? r.applicant?.driver;
      final rawName = (r.name != null && r.name!.trim().isNotEmpty)
          ? r.name!.trim()
          : (driver?.name != null && driver!.name.trim().isNotEmpty
              ? driver.name.trim()
              : "");
      final rawNick = (r.nickname != null && r.nickname!.trim().isNotEmpty)
          ? r.nickname!.trim()
          : (driver?.nickname != null && driver!.nickname!.trim().isNotEmpty
              ? driver.nickname!.trim()
              : "");

      if (rawName.isNotEmpty && rawNick.isNotEmpty && rawName.toLowerCase() != rawNick.toLowerCase()) {
        posterName = "$rawName ($rawNick)";
      } else if (rawName.isNotEmpty) {
        posterName = rawName;
      } else if (rawNick.isNotEmpty) {
        posterName = rawNick;
      } else {
        posterName = r.companyName ?? driver?.company ?? "Unknown";
      }

      posterCompany = r.company ?? driver?.company ?? r.companyName ?? "Unknown";
      participantId = driver?.id ?? "";
      posterImage = (r.profilePicture != null && r.profilePicture!.isNotEmpty)
          ? r.profilePicture!
          : ((driver?.profilePicture != null && driver!.profilePicture.isNotEmpty)
              ? driver.profilePicture
              : AppImages.profile_image);
      rating = driver?.averageRating?.toString() ?? "0.0";

      if (driver?.vehicles != null && driver!.vehicles!.isNotEmpty) {
        final v = driver.vehicles!.first;
        vehicleInfo = "${v.make} ${v.model}, ${v.colorOutside}";
        vehicleNumber = v.licensePlate.isNotEmpty ? v.licensePlate : "N/A";
      } else {
        vehicleInfo = vehicleType;
      }

      dateRaw = r.date?.toString() ?? "";
      timeRaw = r.time ?? "";
    } else if (ride is Map<String, dynamic>) {
      id = ride['bookingNo']?.toString() ?? ride['id']?.toString() ?? '';
      pickupLocation = ride['pickup'] ?? ride['pickupLocation'] ?? 'N/A';
      dropoffLocation = ride['dropoff'] ?? ride['dropoffLocation'] ?? 'N/A';
      vehicleType = ride['type'] ?? ride['vehicleType'] ?? 'N/A';
      paymentType = formatPayment(ride['payment'] ?? ride['paymentType']);
      amount = ride['price'] != null ? "\$${ride['price']}" : "N/A";
      flightNumber = ride['flight'] ?? ride['flightNumber'] ?? 'N/A';
      instruction =
          ride['instructions'] ?? ride['specialInstructions'] ?? 'N/A';
      final rawName = (ride['name'] ??
              ride['jobPoster'] ??
              ride['passenger'] ??
              ride['driver'] ??
              '')
          .toString()
          .trim();
      final rawNick = (ride['nickname'] ?? '').toString().trim();
      if (rawName.isNotEmpty &&
          rawNick.isNotEmpty &&
          rawName.toLowerCase() != rawNick.toLowerCase()) {
        posterName = "$rawName ($rawNick)";
      } else if (rawName.isNotEmpty) {
        posterName = rawName;
      } else if (rawNick.isNotEmpty) {
        posterName = rawNick;
      } else {
        posterName = 'Mohamed El Bakkali';
      }
      vehicleInfo = ride['vehicle'] ?? vehicleType;
      vehicleNumber = ride['vehicle'] ?? 'N/A';
      dateRaw = ride['dateHeader'] ?? ride['date'] ?? '';
      timeRaw = ride['time'] ?? '';
    }

    // --- DATE & TIME FORMATTING (12h AM/PM) ---
    String displayDateTime = "N/A";

    bool isAsap = false;
    if (ride is RideData) {
      isAsap = ride.asap == true;
    } else if (ride is Map) {
      isAsap = ride['asap'] == true;
    }

    if (isAsap) {
      String datePart = "Today";
      if (ride is RideData && ride.createdAt != null && ride.createdAt!.isNotEmpty) {
        try {
          final parsedDate = DateTime.parse(ride.createdAt!).toLocal();
          datePart = "Today, ${DateFormat('MMM dd').format(parsedDate)}";
        } catch (_) {}
      } else if (ride is Map && ride['createdAt'] != null) {
        try {
          final parsedDate = DateTime.parse(ride['createdAt'].toString()).toLocal();
          datePart = "Today, ${DateFormat('MMM dd').format(parsedDate)}";
        } catch (_) {}
      }
      displayDateTime = "$datePart • ASAP";
    } else {
      String dateStr = "";
      if (dateRaw.isNotEmpty) {
        try {
          DateTime parsed = DateTime.parse(dateRaw);
          dateStr = DateFormat('EEE MMM dd').format(parsed);
        } catch (_) {
          dateStr = dateRaw;
        }
      }

      String formattedTime = timeRaw;
      if (timeRaw.contains(':')) {
        try {
          final parts = timeRaw.split(':');
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1].split(' ')[0]);
          final period = hour >= 12 ? "PM" : "AM";
          final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          formattedTime =
              "${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
        } catch (_) {}
      }
      displayDateTime = dateStr.isNotEmpty
          ? "$dateStr . $formattedTime"
          : formattedTime;
    }

    return _RideDetailsData(
      id: id,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      vehicleType: vehicleType,
      paymentType: paymentType,
      amount: amount,
      rating: rating,
      posterName: posterName,
      posterCompany: posterCompany,
      participantId: participantId,
      posterImage: posterImage,
      vehicleInfo: vehicleInfo,
      vehicleNumber: vehicleNumber,
      flightNumber: flightNumber,
      instruction: instruction,
      displayDateTime: displayDateTime,
    );
  }
}
