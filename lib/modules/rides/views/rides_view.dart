import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/my_rides_model.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/core/services/subscription_service.dart';
import 'package:moeb_26/core/widgets/premium_lock_widget.dart';
import 'package:moeb_26/modules/rides/widgets/RideCard.dart';
import '../../../core/widgets/Custom_AppBar.dart';
import '../controllers/rides_controller.dart';

class RidesView extends StatefulWidget {
  const RidesView({super.key});

  @override
  State<RidesView> createState() => _RidesViewState();
}

class _RidesViewState extends State<RidesView> {
  final RidesController controller = Get.find<RidesController>();
  final List<String> _tabs = ["Upcoming", "Past"];

  String _formatDateHeader(RideData ride) =>
      RidesController.formatDateHeader(ride);

  String _formatTime(RideData ride) {
    if (ride.asap) {
      return "ASAP";
    }
    final timeStr = ride.time;
    if (timeStr == null || timeStr.isEmpty) return "N/A";
    if (timeStr.contains(':')) {
      try {
        final parts = timeStr.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1].split(' ')[0]);
        final period = hour >= 12 ? "PM" : "AM";
        final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return "${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
      } catch (_) {}
    }
    return timeStr;
  }

  String _getVehicleInfo(RideData ride) {
    final driver = ride.assignedTo ?? ride.effectiveApplicantDriver;
    if (driver?.vehicles != null && driver!.vehicles!.isNotEmpty) {
      final v = driver.vehicles!.first;
      return "${v.make} ${v.model}, ${v.colorOutside}";
    }
    return ride.vehicleType;
  }

  String _getJobPosterName(RideData ride) {
    if (ride.nickname != null && ride.nickname!.trim().isNotEmpty) {
      return ride.nickname!;
    }
    if (ride.name != null && ride.name!.trim().isNotEmpty) {
      return ride.name!;
    }
    if (ride.createdBy?.nickname != null &&
        ride.createdBy!.nickname!.trim().isNotEmpty) {
      return ride.createdBy!.nickname!;
    }
    if (ride.createdBy?.name != null &&
        ride.createdBy!.name.trim().isNotEmpty) {
      return ride.createdBy!.name;
    }
    if (ride.company != null && ride.company!.trim().isNotEmpty) {
      return ride.company!;
    }
    if (ride.passengerName != null && ride.passengerName!.trim().isNotEmpty) {
      return ride.passengerName!;
    }
    return "Job Poster";
  }

  String _getDriverName(RideData ride) {
    final driver = ride.assignedTo ?? ride.effectiveApplicantDriver;
    if (driver?.nickname != null && driver!.nickname!.trim().isNotEmpty) {
      return driver.nickname!;
    }
    if (driver?.name != null && driver!.name.trim().isNotEmpty) {
      return driver.name;
    }
    return "Assigned Driver";
  }

  Map<String, List<RideData>> _groupRidesByDate(List<RideData> rides) {
    final Map<String, List<RideData>> grouped = {};
    for (final ride in rides) {
      final header = _formatDateHeader(ride);
      if (!grouped.containsKey(header)) {
        grouped[header] = [];
      }
      grouped[header]!.add(ride);
    }
    return grouped;
  }

  String get _currentUserId {
    return Get.isRegistered<UserService>()
        ? Get.find<UserService>().userId
        : "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(title: "My Rides", notificationCount: 3),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 15.h),

            /// CUSTOM TAB BAR
            _buildTabBar(),
            SizedBox(height: 15.h),

            /// RIDES LIST
            Expanded(
              child: Obx(() {
                final isPrem = Get.isRegistered<SubscriptionService>()
                    ? Get.find<SubscriptionService>().isPremium.value
                    : false;

                if (!isPrem) {
                  return const PremiumLockWidget(
                    icon: Icons.directions_car_filled_rounded,
                    title: "Unlock Your Active Rides",
                    description:
                        "Subscribe to Ekkali Premium to manage assigned rides, accept chauffeur bookings, and track active trip statuses.",
                  );
                }

                return controller.selectedTab.value == 0
                    ? _buildUpcomingList()
                    : _buildPastList();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: const Color(0xff161619),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFF24242A)),
        ),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            bool isSelected = controller.selectedTab.value == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.changeTab(index);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      _tabs[index],
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 14.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _buildUpcomingList() {
    if (controller.isLoadingList.value && controller.upcomingRides.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (controller.upcomingRides.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: controller.refreshCurrentTab,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120.h),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 48.sp,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "No upcoming rides found",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA1A1A1),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupRidesByDate(controller.upcomingRides);
    final myId = _currentUserId;

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: controller.refreshCurrentTab,
      child: ListView.builder(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: 20.h),
        itemCount: grouped.keys.length + (controller.isLoadMore.value ? 1 : 0),
        itemBuilder: (context, groupIndex) {
          if (groupIndex == grouped.keys.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              ),
            );
          }

          final dateHeader = grouped.keys.elementAt(groupIndex);
          final rides = grouped[dateHeader]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Padding(
                padding: EdgeInsets.only(top: 15.h, bottom: 10.h, left: 4.w),
                child: Text(
                  dateHeader,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...rides.map((ride) {
                final displayTime = _formatTime(ride);
                final posterName = _getJobPosterName(ride);
                final driverName = _getDriverName(ride);
                final vehicleInfo = _getVehicleInfo(ride);
                final bool isMyJob = ride.isCreatedBy(myId);

                return RideCard(
                  time: displayTime,
                  pickupLocation: ride.pickupLocation,
                  dropoffLocation: Helpers.formatDropoffDisplay(
                    jobType: ride.jobType,
                    dropoffLocation: ride.dropoffLocation,
                    duration: ride.duration,
                  ),
                  jobPosterName: posterName,
                  driverName: driverName,
                  vehicleInfo: vehicleInfo,
                  vehicleType: ride.vehicleType,
                  price: ride.paymentAmount != null
                      ? "${ride.paymentAmount}"
                      : "0.00",
                  paymentType: ride.paymentType,
                  status: ride.status ?? "ASSIGNED",
                  isCreatedByMe: isMyJob,
                  hasApplicant: ride.hasApplicants,
                  applicantCount: ride.applicantCount,
                  onChatTap: () => _openChatWithUser(ride),
                  onTap: () => _openDetailSheet(
                    ride,
                    dateHeader,
                    isPast: false,
                    isCreatedByMe: isMyJob,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPastList() {
    if (controller.isLoadingList.value && controller.pastRides.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (controller.pastRides.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: controller.refreshCurrentTab,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120.h),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 48.sp,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "No past rides found",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA1A1A1),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupRidesByDate(controller.pastRides);
    final myId = _currentUserId;

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: controller.refreshCurrentTab,
      child: ListView.builder(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: 20.h),
        itemCount: grouped.keys.length + (controller.isLoadMore.value ? 1 : 0),
        itemBuilder: (context, groupIndex) {
          if (groupIndex == grouped.keys.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              ),
            );
          }

          final dateHeader = grouped.keys.elementAt(groupIndex);
          final rides = grouped[dateHeader]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Padding(
                padding: EdgeInsets.only(top: 15.h, bottom: 10.h, left: 4.w),
                child: Text(
                  dateHeader,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...rides.map((ride) {
                final displayTime = _formatTime(ride);
                final posterName = _getJobPosterName(ride);
                final driverName = _getDriverName(ride);
                final vehicleInfo = _getVehicleInfo(ride);
                final bool isMyJob = ride.isCreatedBy(myId);

                return RideCard(
                  time: displayTime,
                  pickupLocation: ride.pickupLocation,
                  dropoffLocation: Helpers.formatDropoffDisplay(
                    jobType: ride.jobType,
                    dropoffLocation: ride.dropoffLocation,
                    duration: ride.duration,
                  ),
                  jobPosterName: posterName,
                  driverName: driverName,
                  vehicleInfo: vehicleInfo,
                  vehicleType: ride.vehicleType,
                  price: ride.paymentAmount != null
                      ? "${ride.paymentAmount}"
                      : "0.00",
                  paymentType: ride.paymentType,
                  status: ride.status ?? "COMPLETED",
                  isCreatedByMe: isMyJob,
                  hasApplicant: ride.hasApplicants,
                  applicantCount: ride.applicantCount,
                  onTap: () => _openDetailSheet(
                    ride,
                    dateHeader,
                    isPast: true,
                    isCreatedByMe: isMyJob,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _openChatWithUser(RideData ride) async {
    final String? participantId =
        ride.createdBy?.id ?? ride.assignedTo?.id ?? ride.effectiveApplicantDriver?.id;
    if (participantId != null && participantId.isNotEmpty) {
      try {
        final socketRepo = Get.isRegistered<SocketRepository>()
            ? Get.find<SocketRepository>()
            : Get.put(SocketRepository(apiClient: Get.find<ApiClient>()));

        final chat = await socketRepo.createChat(participantId);
        if (chat != null) {
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

  void _openDetailSheet(
    RideData ride,
    String dateHeader, {
    required bool isPast,
    required bool isCreatedByMe,
  }) {
    controller.showRideDetailSheet(
      ride,
      isPast: isPast,
      isCreatedByMe: isCreatedByMe,
      dateHeader: dateHeader,
    );
  }
}
