import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/constants/image_paths.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/Custom_Card_Ditails.dart';
import 'package:moeb_26/core/widgets/Custom_InfoBox.dart';
import 'package:moeb_26/data/models/my_jobs_model.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';
import '../../my_jobs/controllers/my_jobs_controller.dart';

class MyJobProgressDetailsView extends StatefulWidget {
  const MyJobProgressDetailsView({super.key});

  @override
  State<MyJobProgressDetailsView> createState() =>
      _MyJobProgressDetailsViewState();
}

class _MyJobProgressDetailsViewState extends State<MyJobProgressDetailsView> {
  final BookingController controller = Get.isRegistered<BookingController>()
      ? Get.find<BookingController>()
      : Get.put(BookingController());
  SocketService? socketService;
  final List<Worker> _socketWorkers = [];
  JobData? initialJob;
  String? jobId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is JobData) {
      initialJob = args;
      jobId = args.id;
    } else if (args is Map) {
      initialJob = args['job'] as JobData?;
      jobId = args['jobId']?.toString() ?? initialJob?.id;
    } else if (args is String) {
      jobId = args;
    }

    if (initialJob != null) {
      controller.myJobView.value = initialJob;
    }

    if (Get.isRegistered<SocketService>()) {
      socketService = Get.find<SocketService>();
    }

    _setupJobSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshJob();
    });
  }

  void _setupJobSocket() {
    if (socketService == null || jobId == null || jobId!.isEmpty) return;

    // 1. Join the job room
    socketService!.joinJob(jobId!);

    // 2. Listen for Ride Status Updates (RIDE_STATUS_UPDATED)
    _socketWorkers.add(
      ever(socketService!.lastRideStatusUpdated, (data) {
        if (data == null) return;
        try {
          String? updatedJobId;
          String? newRideStatus;

          if (data is Map) {
            updatedJobId = data['jobId']?.toString() ??
                data['id']?.toString() ??
                data['_id']?.toString();
            newRideStatus =
                data['rideStatus']?.toString() ?? data['status']?.toString();
          }

          if (updatedJobId == jobId && newRideStatus != null) {
            debugPrint(
              "✨ MyJobProgressDetails: Live status updated to: $newRideStatus",
            );
            if (controller.myJobView.value != null) {
              controller.myJobView.value!.rideStatus = newRideStatus;
              controller.myJobView.refresh();
            }
          }
        } catch (e) {
          debugPrint("❌ MyJobProgressDetails: Error handling RIDE_STATUS_UPDATED: $e");
        }
      }),
    );

    // 3. Listen for Job Cancellation (JOB_CANCELLED)
    _socketWorkers.add(
      ever(socketService!.lastJobCancelled, (data) {
        if (data == null) return;
        try {
          String? cancelledJobId;
          if (data is Map) {
            cancelledJobId = data['jobId']?.toString() ??
                data['id']?.toString() ??
                data['_id']?.toString();
          } else if (data is String) {
            cancelledJobId = data;
          }

          if (cancelledJobId == jobId) {
            debugPrint("🚨 MyJobProgressDetails: Live job cancelled");
            if (controller.myJobView.value != null) {
              controller.myJobView.value!.status = "CANCELLED";
              controller.myJobView.value!.rideStatus = "CANCELLED";
              controller.myJobView.refresh();
            }
            Helpers.showCustomSnackBar(
              "This ride has been cancelled.",
              isError: true,
            );
          }
        } catch (e) {
          debugPrint("❌ MyJobProgressDetails: Error handling JOB_CANCELLED: $e");
        }
      }),
    );
  }

  @override
  void dispose() {
    if (socketService != null && jobId != null && jobId!.isNotEmpty) {
      socketService!.leaveJob(jobId!);
    }
    for (var worker in _socketWorkers) {
      worker.dispose();
    }
    _socketWorkers.clear();
    super.dispose();
  }

  Future<void> _refreshJob() async {
    if (jobId == null) {
      debugPrint("⚠️ MyJobProgressDetails: jobId is null, cannot refresh");
      return;
    }
    debugPrint(
      "🔄 MyJobProgressDetails: Refreshing job details for jobId: $jobId",
    );
    try {
      await controller.fetchJobDetails(jobId: jobId!);
      debugPrint("✨ MyJobProgressDetails: Refresh completed");
    } catch (e) {
      debugPrint("❌ MyJobProgressDetails: Refresh failed: $e");
    }
  }

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
              'Job Details',
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
        child: RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () async {
            await _refreshJob();
          },
          child: Obx(() {
            final job = controller.myJobView.value;

            if (job == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              );
            }

            // Format date and time
            String displayDateTime = "N/A";
            if (job.asap == true) {
              displayDateTime = "ASAP";
            } else {
              String dateStr = "";
              if (job.date != null &&
                  job.date != "null" &&
                  job.date!.isNotEmpty) {
                try {
                  DateTime parsedDate = DateTime.parse(job.date!);
                  dateStr = DateFormat('EEE MMM dd').format(parsedDate);
                } catch (_) {
                  dateStr = job.date!;
                }
              }

              String timeStr = job.time ?? "";
              if (timeStr.contains(':')) {
                try {
                  final parts = timeStr.split(':');
                  int hour = int.parse(parts[0]);
                  int minute = int.parse(parts[1].split(' ')[0]);
                  final period = hour >= 12 ? "PM" : "AM";
                  final hour12 = hour == 0
                      ? 12
                      : (hour > 12 ? hour - 12 : hour);
                  timeStr =
                      "${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
                } catch (_) {}
              }
              displayDateTime = dateStr.isNotEmpty
                  ? "$dateStr . $timeStr"
                  : timeStr;
            }

            final driver = job.assignedTo ?? job.applicant?.driver;
            final vehicle =
                (driver?.vehicles != null && driver!.vehicles!.isNotEmpty)
                ? driver.vehicles!.first
                : null;
            final vehicleInfo = vehicle != null
                ? "${vehicle.make} ${vehicle.model}, ${vehicle.colorOutside}"
                : job.vehicleType ?? "N/A";

            String driverDisplayName = "Driver";
            if (driver != null) {
              final hasName = driver.name != null && driver.name!.trim().isNotEmpty;
              final hasNick = driver.nickname != null && driver.nickname!.trim().isNotEmpty;
              if (hasName && hasNick && driver.name!.trim().toLowerCase() != driver.nickname!.trim().toLowerCase()) {
                driverDisplayName = "${driver.name!.trim()} (${driver.nickname!.trim()})";
              } else if (hasName) {
                driverDisplayName = driver.name!.trim();
              } else if (hasNick) {
                driverDisplayName = driver.nickname!.trim();
              }
            }

            final String? participantId =
                driver?.id ?? job.assignedTo?.id ?? job.applicant?.driver?.id;
            final String driverProfileImage = driver?.profilePicture ??
                job.assignedTo?.profilePicture ??
                job.applicant?.driver?.profilePicture ??
                AppImages.profile_image;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOwnerProgressTracker(
                        job.rideStatus ?? "",
                        job.status ?? "",
                      ),
                      SizedBox(height: 6.h),
                      _buildDriverSection(
                        driverName: driverDisplayName,
                        driverImage: driverProfileImage,
                        rating: "${driver?.averageRating ?? 0.0}",
                        onProfilePressed: (participantId != null && participantId.isNotEmpty)
                            ? () {
                                final preferredController =
                                    Get.isRegistered<PreferredDriversController>()
                                        ? Get.find<PreferredDriversController>()
                                        : Get.put(PreferredDriversController());

                                preferredController.openChauffeurProfile(
                                  userId: participantId,
                                  name: driver?.name ?? driver?.nickname ?? 'Chauffeur',
                                  imageUrl: driver?.profilePicture ?? '',
                                );
                              }
                            : null,
                        onChatPressed: () async {
                          if (participantId != null && participantId.isNotEmpty) {
                            try {
                              final socketRepo = Get.isRegistered<SocketRepository>()
                                  ? Get.find<SocketRepository>()
                                  : Get.put(SocketRepository(apiClient: Get.find<ApiClient>()));

                              final chat = await socketRepo.createChat(participantId);
                              if (chat != null) {
                                Get.toNamed(
                                  Routes.chatDetailView,
                                  arguments: chat,
                                );
                                return;
                              }
                            } catch (e) {
                              debugPrint("Error opening chat: $e");
                              Helpers.showCustomSnackBar(
                                "Could not create chat session. Please try again.",
                                isError: true,
                              );
                              return;
                            }
                          }

                          Helpers.showCustomSnackBar(
                            "Chauffeur is not available to chat right now.",
                            isError: true,
                          );
                        },
                      ),
                      SizedBox(height: 12.h),

                      // Status Steps Container
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: CustomJobDetailsCard(
                          // Location details
                          pickupLocation: job.pickupLocation ?? "N/A",
                          dropoffLocation: job.dropoffLocation ?? "N/A",

                          // Job information
                          flightNumber: job.flightNumber ?? "N/A",
                          dateTime: displayDateTime,
                          vehicleType: vehicleInfo,
                          jobPoster:
                              (job.createdBy?.nickname != null &&
                                  job.createdBy!.nickname!.isNotEmpty)
                              ? job.createdBy!.nickname!
                              : (job.createdBy?.name ?? "Unknown"),
                          company: driver?.company ?? "N/A",
                          payment: job.paymentType ?? "N/A",
                          amount: "\$${job.paymentAmount}",

                          // Optional: Custom colors matching Invoice Theme
                          backgroundColor: const Color(0xFF1A1A1A),
                          borderColor: const Color(0xFF2C2C2C),
                          labelColor: const Color(0xFFA1A1A1),
                          valueColor: Colors.white,
                          iconColor: Colors.white70,
                          amountColor: const Color(0xFFFEDB9B),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      if (job.instruction != null &&
                          job.instruction!.trim().isNotEmpty) ...[
                        CustomInfoBox(
                          text: job.instruction!,
                          title: "Special Instructions",
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                        ),
                        SizedBox(height: 12.h),
                      ],

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: Builder(
                          builder: (context) {
                            final status = job.status?.toUpperCase() ?? "";
                            final rideStatus =
                                job.rideStatus?.toUpperCase() ?? "";

                            bool isCancelled =
                                status == "CANCELLED" ||
                                rideStatus == "CANCELLED";
                            bool isCompleted =
                                rideStatus == "FINISHED" ||
                                rideStatus == "COMPLETED" ||
                                status == "COMPLETED";

                            if (isCompleted) {
                              if (job.hasReview == true) {
                                return Container(
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFF10B981),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        "Review Submitted",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              // Ride finished, show Review button
                              return CustomButton(
                                text: "Review Driver",
                                backgroundColor: AppColors.primaryColor,
                                textColor: Colors.black,
                                onPressed: () {
                                  Get.toNamed(
                                    Routes.rideCompletedView,
                                    arguments: job,
                                  );
                                },
                              );
                            } else if (!isCancelled && rideStatus != "POB") {
                              // Ride can still be cancelled before POB
                              return CustomButton(
                                text: "Cancel Ride",
                                backgroundColor: const Color(0xFF2A1C1C),
                                borderColor: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.5),
                                textColor: const Color(0xFFEF4444),
                                onPressed: () {
                                  if (job.id != null) {
                                    _showDeleteDialog(job.id!);
                                  }
                                },
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildOwnerProgressTracker(String rideStatus, String status) {
    final rStatus = rideStatus.toUpperCase();
    final jStatus = status.toUpperCase();

    if (jStatus == "CANCELLED" || rStatus == "CANCELLED") {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: const Color(0xFFEF4444),
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                "This job has been cancelled.",
                style: GoogleFonts.inter(
                  color: const Color(0xFFEF4444),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    int activeStep = 0;
    if (rStatus == "ON THE WAY") {
      activeStep = 1;
    } else if (rStatus == "AT THE LOCATION") {
      activeStep = 2;
    } else if (rStatus == "POB") {
      activeStep = 3;
    } else if (rStatus == "FINISHED" ||
        rStatus == "COMPLETED" ||
        jStatus == "COMPLETED") {
      activeStep = 4;
    }

    final steps = [
      {"label": "Assigned", "icon": Icons.assignment_turned_in_outlined},
      {"label": "On The Way", "icon": Icons.directions_car_outlined},
      {"label": "At Location", "icon": Icons.location_on_outlined},
      {"label": "POB", "icon": Icons.person_pin_circle_outlined},
      {"label": "Completed", "icon": Icons.task_alt},
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
                "Driver Live Status",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isFinished
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : AppColors.orange100.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isFinished
                        ? const Color(0xFF10B981)
                        : AppColors.orange100,
                  ),
                ),
                child: Text(
                  rStatus.isEmpty ? "ASSIGNED" : rStatus,
                  style: GoogleFonts.inter(
                    color: isFinished
                        ? const Color(0xFF10B981)
                        : AppColors.orange100,
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
                        ? AppColors.orange100
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
                                        ? AppColors.orange100.withValues(
                                            alpha: 0.15,
                                          )
                                        : Colors.white.withValues(alpha: 0.05)),
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
  }

  Widget _buildDriverSection({
    required String driverName,
    required String driverImage,
    required String rating,
    VoidCallback? onProfilePressed,
    required VoidCallback onChatPressed,
  }) {
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
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onProfilePressed,
              child: Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF24242A),
                      border: Border.all(
                        color: const Color(0xFF33333E),
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
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person_outline,
                                    color: const Color(0xFFFEDB9B),
                                    size: 20.sp,
                                  ),
                                ))
                          : Icon(
                              Icons.person_outline,
                              color: const Color(0xFFFEDB9B),
                              size: 20.sp,
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                driverName,
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onProfilePressed != null) ...[
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: const Color(0xFF94A3B8),
                                size: 10.sp,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Assigned Driver • ⭐ $rating",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFA1A1A1),
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
          IconButton(
            onPressed: onChatPressed,
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.orange100.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.orange100),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.orange100,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= DELETE DIALOG =================
  void _showDeleteDialog(String jobId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFF2C2C2C)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Are you sure to cancel the ride?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: const Color(0xFF2C2C2C)),
                        ),
                        child: Center(
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (Get.isDialogOpen == true) {
                          Get.back(); // 1. Close dialog
                        }
                        final success =
                            await controller.cancelJobOffer(jobId: jobId);
                        if (success) {
                          Get.back(); // 2. Exit ride details page and return to My Jobs
                          Helpers.showCustomSnackBar(
                            'Job cancelled successfully.',
                            isError: false,
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Center(
                          child: Text(
                            "Yes",
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
