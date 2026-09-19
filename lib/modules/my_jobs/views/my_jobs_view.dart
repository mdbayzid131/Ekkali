import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/my_jobs_model.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/modules/my_jobs/widgets/MyJobCard.dart';
import 'package:moeb_26/modules/my_jobs/widgets/MyJobDetailSheet.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import '../controllers/my_jobs_controller.dart';

import 'package:intl/intl.dart';

class MyJobsView extends StatefulWidget {
  const MyJobsView({super.key});

  @override
  State<MyJobsView> createState() => _MyJobsViewState();
}

class _MyJobsViewState extends State<MyJobsView> {
  final BookingController controller = Get.find<BookingController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchJobs(isRefresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        controller.loadMoreMyJobs();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDateHeader(String? dateStr, String? createdAtStr) {
    DateTime? dt;
    if (dateStr != null && dateStr.isNotEmpty) {
      dt = DateTime.tryParse(dateStr);
    }
    if (dt == null && createdAtStr != null && createdAtStr.isNotEmpty) {
      dt = DateTime.tryParse(createdAtStr);
    }
    if (dt == null) return "Recent Jobs";

    final localDt = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final jobDay = DateTime(localDt.year, localDt.month, localDt.day);

    if (jobDay == today) return "Today, ${DateFormat('MMM dd').format(localDt)}";
    if (jobDay == today.add(const Duration(days: 1))) {
      return "Tomorrow, ${DateFormat('MMM dd').format(localDt)}";
    }

    return DateFormat('EEE, MMM dd').format(localDt);
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dt = DateTime(2026, 1, 1, hour, minute);
        return DateFormat('h:mm a').format(dt);
      }
    } catch (_) {}
    return timeStr;
  }

  Map<String, List<JobData>> _groupJobsByDate(List<JobData> jobs) {
    final Map<String, List<JobData>> groups = {};
    for (final job in jobs) {
      final header = _formatDateHeader(job.date, job.createdAt);
      groups.putIfAbsent(header, () => []).add(job);
    }
    return groups;
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
              onPressed: () {
                controller.setJobAcceptanceView(false);
                Get.toNamed(Routes.bottomNabbarView);
              },
            ),
            title: Text(
              'My Created Jobs',
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
        if (controller.isJobsLoading.value && controller.myJobsList.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFEDB9B)),
          );
        }

        if (controller.myJobsList.isEmpty) {
          return RefreshIndicator(
            color: const Color(0xFFFEDB9B),
            onRefresh: () => controller.fetchJobs(isRefresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 150.h),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        size: 60.sp,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No created jobs found',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Jobs you create will appear here.',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final groupedJobs = _groupJobsByDate(controller.myJobsList);
        final groupHeaders = groupedJobs.keys.toList();

        return RefreshIndicator(
          color: const Color(0xFFFEDB9B),
          onRefresh: () => controller.fetchJobs(isRefresh: true),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            itemCount: groupHeaders.length + (controller.isMyJobsLoadMore.value ? 1 : 0),
            itemBuilder: (context, groupIndex) {
              if (groupIndex == groupHeaders.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFEDB9B)),
                  ),
                );
              }

              final String dateHeader = groupHeaders[groupIndex];
              final List<JobData> jobs = groupedJobs[dateHeader]!;

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
                  ...jobs.map((job) {
                    final isAsapJob = job.asap == true || (job.time == null || job.time!.isEmpty);
                    final displayTime = isAsapJob ? "ASAP" : _formatTime(job.time);
                    final String displayDriver = (job.status?.toUpperCase() == 'PENDING')
                        ? ((job.applicantCount ?? 0) > 0
                            ? "${job.applicantCount} Applicant Available"
                            : (job.applicant?.driver?.name != null
                                ? "1 Applicant Available"
                                : "Awaiting Chauffeur"))
                        : (job.assignedTo?.name ?? 'Assigned Chauffeur');

                    return MyJobCard(
                      time: displayTime,
                      pickupLocation: job.pickupLocation ?? 'Pickup',
                      dropoffLocation: job.dropoffLocation ?? 'Dropoff',
                      companyName: job.companyName ?? 'My Job',
                      assignedDriver: displayDriver,
                      vehicleType: job.vehicleType ?? 'Sedan',
                      price: job.paymentAmount?.toString(),
                      status: job.status ?? 'PENDING',
                      onTap: () => _openJobDetails(job, dateHeader),
                    );
                  }),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  void _openJobDetails(JobData job, String dateHeader) {
    final String status = job.status ?? 'PENDING';
    final String upperStatus = status.toUpperCase();
    final bool canEdit = upperStatus == 'PENDING';
    final bool canDelete =
        upperStatus == 'PENDING' || upperStatus == 'CANCELLED';

    final isAsapJob = job.asap == true || (job.time == null || job.time!.isEmpty);
    final displayTime = isAsapJob ? "ASAP" : _formatTime(job.time);
    final String driverName = (job.assignedTo?.name?.isNotEmpty == true)
        ? job.assignedTo!.name!
        : (job.applicant?.driver?.name?.isNotEmpty == true
            ? job.applicant!.driver!.name!
            : (upperStatus == 'PENDING'
                ? ((job.applicantCount ?? 0) > 0
                    ? "${job.applicantCount} Applicant Available"
                    : "Awaiting Chauffeur")
                : "Not Assigned"));

    final double? driverRating =
        job.assignedTo?.averageRating ?? job.applicant?.driver?.averageRating;
    final String? driverId = job.assignedTo?.id ?? job.applicant?.driver?.id;
    final String? driverImage =
        job.assignedTo?.profilePicture ?? job.applicant?.driver?.profilePicture;

    final bool hasApplicant = (job.applicant != null && job.applicant?.driver != null) ||
        ((job.applicantCount ?? 0) > 0);

    Get.bottomSheet(
      MyJobDetailSheet(
        title: "Created Job Details",
        bookingNo: job.id ?? '',
        dateTimeStr: "$dateHeader • $displayTime",
        pickupLocation: job.pickupLocation ?? '',
        dropoffLocation: job.dropoffLocation ?? '',
        passengerName: job.companyName ?? 'Fleet Operator',
        driverName: driverName,
        driverId: driverId,
        driverImage: driverImage,
        driverRating: driverRating,
        vehicleInfo: job.vehicleType ?? 'Vehicle',
        vehicleType: job.vehicleType ?? 'Sedan',
        paymentType: job.paymentType ?? 'Credit Card on File',
        amount: job.paymentAmount != null ? job.paymentAmount.toString() : '',
        flightNumber: job.flightNumber,
        specialInstructions: job.instruction,
        status: status,
        isReviewedByCreator: job.isReviewedByCreator ?? false,
        hasApplicant: hasApplicant,
        onAcceptPressed: (hasApplicant && job.id != null)
            ? () {
                controller.approveApplicant(jobId: job.id!);
              }
            : null,
        onRejectPressed: (hasApplicant && job.id != null)
            ? () {
                controller.rejectApplicant(jobId: job.id!);
              }
            : null,
        onChatPressed: () async {
          final String? participantId = driverId;
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
        onActionButtonPressed: () {
          if (upperStatus == 'ASSIGNED' || upperStatus == 'IN PROGRESS') {
            Get.toNamed(
              Routes.myJobProgressDetailsView,
              arguments: job,
            );
          }
        },
        onReviewPressed: () {
          Get.toNamed(Routes.rideCompletedView, arguments: job);
        },
        onEditPressed: canEdit && job.id != null
            ? () {
                Get.back();
                Get.toNamed(Routes.jobEditView, arguments: job);
              }
            : null,
        onDeletePressed: canDelete && job.id != null
            ? () {
                _showDeleteDialog(jobId: job.id!);
              }
            : null,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _showDeleteDialog({required String jobId}) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFF2C2C2C)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Delete Job",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "Are you sure you want to delete this job?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13.sp),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Cancel",
                      backgroundColor: Colors.transparent,
                      textColor: Colors.white,
                      borderColor: Colors.grey,
                      fontSize: 14.sp,
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: CustomButton(
                      text: "Delete",
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.black,
                      fontSize: 14.sp,
                      onPressed: () {
                        Get.back(); // Close confirmation dialog
                        if (Get.isBottomSheetOpen == true) {
                          Get.back(); // Close bottom sheet
                        }
                        controller.deleteJob(jobId: jobId);
                      },
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
