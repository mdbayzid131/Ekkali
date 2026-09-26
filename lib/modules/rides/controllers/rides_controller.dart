import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/data/models/my_rides_model.dart';
import 'package:moeb_26/data/repositories/job_repository.dart';
import 'package:moeb_26/modules/rides/widgets/RideDetailSheet.dart';

class RidesController extends GetxController {
  final JobRepo _jobRepo = Get.find<JobRepo>();
  SocketService? _socketService;
  String? _currentlyOpeningJobId;

  RxBool isLoadingList = false.obs;
  RxBool isLoadMore = false.obs;

  var selectedTab = 0.obs; // 0 = Upcoming, 1 = Past

  // Cursor pagination states
  String? upcomingNextCursor;
  bool upcomingHasMore = false;

  String? pastNextCursor;
  bool pastHasMore = false;

  final ScrollController scrollController = ScrollController();

  RxList<RideData> upcomingRides = <RideData>[].obs;
  RxList<RideData> pastRides = <RideData>[].obs;

  final List<Worker> _socketWorkers = [];

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Map && Get.arguments.containsKey('ridesTab')) {
      selectedTab.value = Get.arguments['ridesTab'];
    }
    if (Get.arguments is Map && Get.arguments.containsKey('targetJobId')) {
      final targetJobId = Get.arguments['targetJobId']?.toString();
      if (targetJobId != null && targetJobId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          openRideBottomSheet(targetJobId);
        });
      }
    }
    if (Get.isRegistered<SocketService>()) {
      _socketService = Get.find<SocketService>();
      _setupSocketListeners();
    }
    if (selectedTab.value == 0) {
      fetchUpcomingJobs();
    } else if (selectedTab.value == 1) {
      fetchPastJobs();
    }
    scrollController.addListener(_onScroll);
  }

  void _setupSocketListeners() {
    if (_socketService == null) return;

    // 1. Listen for Driver Applications (JOB_APPLICATION_RECEIVED)
    _socketWorkers.add(
      ever(_socketService!.lastJobApplication, (data) {
        if (data == null) return;
        try {
          String? targetJobId;
          dynamic applicantData;

          if (data is Map) {
            targetJobId = data['jobId']?.toString() ??
                data['id']?.toString() ??
                data['_id']?.toString();
            applicantData = data['applicant'] ?? data['data'];
          }

          if (targetJobId != null && targetJobId.isNotEmpty) {
            final index = upcomingRides.indexWhere((r) => r.id == targetJobId);
            if (index != -1) {
              final currentRide = upcomingRides[index];
              // Update applicant details if available
              ApplicantData? newApp;
              if (applicantData is Map<String, dynamic>) {
                newApp = ApplicantData.fromJson(applicantData);
              }
              final updatedRide = RideData(
                id: currentRide.id,
                jobCreatorId: currentRide.jobCreatorId,
                jobType: currentRide.jobType,
                pickupLocation: currentRide.pickupLocation,
                dropoffLocation: currentRide.dropoffLocation,
                flightNumber: currentRide.flightNumber,
                asap: currentRide.asap,
                date: currentRide.date,
                time: currentRide.time,
                vehicleType: currentRide.vehicleType,
                paymentAmount: currentRide.paymentAmount,
                paymentType: currentRide.paymentType,
                paymentStatus: currentRide.paymentStatus,
                instruction: currentRide.instruction,
                passengerName: currentRide.passengerName,
                passengerPhone: currentRide.passengerPhone,
                status: currentRide.status,
                rideStatus: currentRide.rideStatus,
                applicantCount: (currentRide.applicantCount ?? 0) + 1,
                name: currentRide.name,
                nickname: currentRide.nickname,
                company: currentRide.company,
                companyName: currentRide.companyName,
                companyRole: currentRide.companyRole,
                profilePicture: currentRide.profilePicture,
                hasReview: currentRide.hasReview,
                isReviewedByDriver: currentRide.isReviewedByDriver,
                isReviewedByCreator: currentRide.isReviewedByCreator,
                createdAt: currentRide.createdAt,
                updatedAt: currentRide.updatedAt,
                createdBy: currentRide.createdBy,
                assignedTo: currentRide.assignedTo,
                applicant: newApp ?? currentRide.applicant,
                applicants: currentRide.applicants,
              );
              upcomingRides[index] = updatedRide;
              upcomingRides.refresh();
            } else {
              refreshCurrentTab();
            }

            debugPrint("✨ RidesController: Real-time application received for [$targetJobId]");
          }
        } catch (e) {
          debugPrint("❌ RidesController: Error handling JOB_APPLICATION_RECEIVED: $e");
        }
      }),
    );

    // 2. Listen for new assigned jobs (JOB_ASSIGNED)
    _socketWorkers.add(
      ever(_socketService!.lastJobAssigned, (data) {
        if (data == null) return;
        try {
          Map<String, dynamic>? jobMap;
          if (data is Map<String, dynamic>) {
            if (data.containsKey('job') && data['job'] is Map<String, dynamic>) {
              jobMap = data['job'];
            } else if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
              jobMap = data['data'];
            } else {
              jobMap = data;
            }
          }

          if (jobMap != null) {
            final newRide = RideData.fromJson(jobMap);
            if (newRide.id.isNotEmpty) {
              final existingIndex = upcomingRides.indexWhere((r) => r.id == newRide.id);
              if (existingIndex != -1) {
                upcomingRides[existingIndex] = newRide;
                upcomingRides.refresh();
              } else {
                upcomingRides.insert(0, newRide);
              }
              Helpers.showCustomSnackBar(
                "You have been assigned to a new ride!",
                isError: false,
              );
              debugPrint("✨ RidesController: Real-time JOB_ASSIGNED added [${newRide.id}]");
            }
          }
        } catch (e) {
          debugPrint("❌ RidesController: Error handling JOB_ASSIGNED: $e");
        }
      }),
    );

    // 3. Listen for Ride Status Updates (RIDE_STATUS_UPDATED)
    _socketWorkers.add(
      ever(_socketService!.lastRideStatusUpdated, (data) {
        if (data == null) return;
        try {
          String? targetJobId;
          String? newStatus;
          if (data is Map) {
            targetJobId = data['jobId']?.toString() ??
                data['id']?.toString() ??
                data['_id']?.toString();
            newStatus = data['rideStatus']?.toString() ?? data['status']?.toString();
          }

          if (targetJobId != null && targetJobId.isNotEmpty) {
            if (newStatus == "FINISHED" || newStatus == "COMPLETED") {
              // Refresh lists to properly move to past rides
              refreshCurrentTab();
            } else if (newStatus != null) {
              final index = upcomingRides.indexWhere((r) => r.id == targetJobId);
              if (index != -1) {
                final current = upcomingRides[index];
                upcomingRides[index] = RideData(
                  id: current.id,
                  jobCreatorId: current.jobCreatorId,
                  jobType: current.jobType,
                  pickupLocation: current.pickupLocation,
                  dropoffLocation: current.dropoffLocation,
                  flightNumber: current.flightNumber,
                  asap: current.asap,
                  date: current.date,
                  time: current.time,
                  vehicleType: current.vehicleType,
                  paymentAmount: current.paymentAmount,
                  paymentType: current.paymentType,
                  paymentStatus: current.paymentStatus,
                  instruction: current.instruction,
                  passengerName: current.passengerName,
                  passengerPhone: current.passengerPhone,
                  status: current.status,
                  rideStatus: newStatus,
                  applicantCount: current.applicantCount,
                  name: current.name,
                  nickname: current.nickname,
                  company: current.company,
                  companyName: current.companyName,
                  companyRole: current.companyRole,
                  profilePicture: current.profilePicture,
                  hasReview: current.hasReview,
                  isReviewedByDriver: current.isReviewedByDriver,
                  isReviewedByCreator: current.isReviewedByCreator,
                  createdAt: current.createdAt,
                  updatedAt: current.updatedAt,
                  createdBy: current.createdBy,
                  assignedTo: current.assignedTo,
                  applicant: current.applicant,
                  applicants: current.applicants,
                );
                upcomingRides.refresh();
              }
            }
          }
        } catch (e) {
          debugPrint("❌ RidesController: Error handling RIDE_STATUS_UPDATED: $e");
        }
      }),
    );

    // 4. Listen for Job Cancellations (JOB_CANCELLED)
    _socketWorkers.add(
      ever(_socketService!.lastJobCancelled, (data) {
        if (data == null) return;
        try {
          String? targetJobId;
          if (data is Map) {
            targetJobId = data['jobId']?.toString() ??
                data['id']?.toString() ??
                data['_id']?.toString();
          } else if (data is String) {
            targetJobId = data;
          }

          if (targetJobId != null && targetJobId.isNotEmpty) {
            upcomingRides.removeWhere((r) => r.id == targetJobId);
            debugPrint("🗑️ RidesController: Real-time cancelled ride removed [$targetJobId]");
          }
        } catch (e) {
          debugPrint("❌ RidesController: Error handling JOB_CANCELLED: $e");
        }
      }),
    );
  }

  @override
  void onClose() {
    for (var worker in _socketWorkers) {
      worker.dispose();
    }
    _socketWorkers.clear();
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!scrollController.hasClients ||
        scrollController.positions.length != 1) {
      return;
    }
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingList.value &&
        !isLoadMore.value) {
      if (selectedTab.value == 0) {
        if (upcomingHasMore && upcomingNextCursor != null) {
          loadMoreUpcomingJobs();
        }
      } else if (selectedTab.value == 1) {
        if (pastHasMore && pastNextCursor != null) {
          loadMorePastJobs();
        }
      }
    }
  }

  Future<void> fetchUpcomingJobs() async {
    try {
      isLoadingList.value = true;
      upcomingNextCursor = null;
      final response = await _jobRepo.getUpcomingJobs(cursor: null);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final ridesResponse = MyRidesModel.fromJson(response.data);
          upcomingRides.assignAll(ridesResponse.data);
          upcomingNextCursor = ridesResponse.cursor?.nextCursor;
          upcomingHasMore = ridesResponse.cursor?.hasMore ?? false;
        }
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to fetch upcoming jobs.')
            : 'Failed to fetch upcoming jobs.';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Failed to fetch upcoming jobs.';
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      print("Error fetching upcoming jobs: $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoadingList.value = false;
    }
  }

  Future<void> loadMoreUpcomingJobs() async {
    if (!upcomingHasMore || upcomingNextCursor == null || isLoadMore.value) {
      return;
    }

    try {
      isLoadMore.value = true;
      final response = await _jobRepo.getUpcomingJobs(cursor: upcomingNextCursor);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final ridesResponse = MyRidesModel.fromJson(response.data);
          upcomingRides.addAll(ridesResponse.data);
          upcomingNextCursor = ridesResponse.cursor?.nextCursor;
          upcomingHasMore = ridesResponse.cursor?.hasMore ?? false;
        }
      }
    } catch (e) {
      print("Error loading more upcoming jobs: $e");
    } finally {
      isLoadMore.value = false;
    }
  }

  Future<void> fetchPastJobs() async {
    try {
      isLoadingList.value = true;
      pastNextCursor = null;
      final response = await _jobRepo.getPastJobs(cursor: null);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final ridesResponse = MyRidesModel.fromJson(response.data);
          pastRides.assignAll(ridesResponse.data);
          pastNextCursor = ridesResponse.cursor?.nextCursor;
          pastHasMore = ridesResponse.cursor?.hasMore ?? false;
        }
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to fetch past jobs.')
            : 'Failed to fetch past jobs.';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Failed to fetch past jobs.';
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      print("Error fetching past jobs: $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoadingList.value = false;
    }
  }

  Future<void> loadMorePastJobs() async {
    if (!pastHasMore || pastNextCursor == null || isLoadMore.value) {
      return;
    }

    try {
      isLoadMore.value = true;
      final response = await _jobRepo.getPastJobs(cursor: pastNextCursor);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final ridesResponse = MyRidesModel.fromJson(response.data);
          pastRides.addAll(ridesResponse.data);
          pastNextCursor = ridesResponse.cursor?.nextCursor;
          pastHasMore = ridesResponse.cursor?.hasMore ?? false;
        }
      }
    } catch (e) {
      print("Error loading more past jobs: $e");
    } finally {
      isLoadMore.value = false;
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
    if (index == 0) {
      fetchUpcomingJobs();
    } else if (index == 1) {
      fetchPastJobs();
    }
  }

  Future<void> approveApplicant({required String jobId}) async {
    try {
      isLoadingList.value = true;
      final response = await _jobRepo.approveApplicant(jobId: jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showCustomSnackBar(
          response.data?['message'] ??
              'Applicant approved and job assigned successfully.',
          isError: false,
        );
        await refreshCurrentTab();
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to approve applicant.')
            : 'Failed to approve applicant.';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Failed to approve applicant.';
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      debugPrint("Error approving applicant: $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoadingList.value = false;
    }
  }

  Future<void> rejectApplicant({required String jobId}) async {
    try {
      isLoadingList.value = true;
      final response = await _jobRepo.rejectApplicant(jobId: jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? 'Applicant rejected successfully.',
          isError: false,
        );
        await refreshCurrentTab();
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to reject applicant.')
            : 'Failed to reject applicant.';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Failed to reject applicant.';
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      debugPrint("Error rejecting applicant: $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoadingList.value = false;
    }
  }

  Future<void> deleteJob({required String jobId}) async {
    try {
      isLoadingList.value = true;
      final response = await _jobRepo.deleteJob(jobId: jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        upcomingRides.removeWhere((job) => job.id == jobId);
        pastRides.removeWhere((job) => job.id == jobId);
        Helpers.showCustomSnackBar('Job deleted successfully.', isError: false);
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to delete job.')
            : 'Failed to delete job.';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Failed to delete job.';
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      debugPrint("Error deleting job: $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoadingList.value = false;
    }
  }

  Future<bool> cancelJob({required String jobId}) async {
    try {
      isLoadingList.value = true;
      final response = await _jobRepo.cancelJobOffer(jobId: jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showCustomSnackBar('Job cancelled successfully.', isError: false);
        await refreshCurrentTab();
        return true;
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to cancel job.')
            : 'Failed to cancel job.';
        Helpers.showCustomSnackBar(message, isError: true);
        return false;
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Failed to cancel job.';
      Helpers.showCustomSnackBar(message, isError: true);
      return false;
    } catch (e) {
      debugPrint("Error canceling job: $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
      return false;
    } finally {
      isLoadingList.value = false;
    }
  }

  Future<void> refreshCurrentTab() async {
    if (selectedTab.value == 0) {
      await fetchUpcomingJobs();
    } else if (selectedTab.value == 1) {
      await fetchPastJobs();
    }
  }

  static String formatDateHeader(RideData ride) {
    DateTime? parsed;
    if (ride.asap) {
      if (ride.createdAt != null && ride.createdAt!.isNotEmpty) {
        try {
          parsed = DateTime.parse(ride.createdAt!).toLocal();
        } catch (_) {}
      }
      parsed ??= DateTime.now();
    } else {
      final dateStr = ride.date;
      if (dateStr != null && dateStr.isNotEmpty && dateStr != "null") {
        try {
          parsed = DateTime.parse(dateStr).toLocal();
        } catch (_) {}
      }
      if (parsed == null &&
          ride.createdAt != null &&
          ride.createdAt!.isNotEmpty) {
        try {
          parsed = DateTime.parse(ride.createdAt!).toLocal();
        } catch (_) {}
      }
    }

    if (parsed == null) {
      return "Scheduled";
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final rideDate = DateTime(parsed.year, parsed.month, parsed.day);

      if (rideDate == today) {
        return "Today, ${DateFormat('MMM dd').format(parsed)}";
      } else if (rideDate == today.add(const Duration(days: 1))) {
        return "Tomorrow, ${DateFormat('MMM dd').format(parsed)}";
      } else if (rideDate == today.subtract(const Duration(days: 1))) {
        return "Yesterday, ${DateFormat('MMM dd').format(parsed)}";
      } else if (parsed.year != now.year) {
        return DateFormat('EEE, MMM dd, yyyy').format(parsed);
      } else {
        return DateFormat('EEE, MMM dd').format(parsed);
      }
    } catch (_) {
      return DateFormat('MMM dd').format(parsed);
    }
  }

  void showDeleteDialog({required String jobId}) {
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
                        deleteJob(jobId: jobId);
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

  Future<void> showRideDetailSheet(
    RideData ride, {
    required bool isPast,
    required bool isCreatedByMe,
    String? dateHeader,
  }) async {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (Get.isDialogOpen == true) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    Get.bottomSheet(
      RideDetailSheet(
        ride: ride,
        isPast: isPast,
        dateHeader: dateHeader ?? formatDateHeader(ride),
        isCreatedByMe: isCreatedByMe,
        onReviewPressed: (isPast &&
                ride.status?.toUpperCase() != 'CANCELLED' &&
                ride.rideStatus?.toUpperCase() != 'CANCELLED')
            ? () {
                Get.toNamed(Routes.rideCompletedView, arguments: ride);
              }
            : null,
        onEditPressed: isCreatedByMe && !ride.hasApplicants
            ? () {
                Get.toNamed(Routes.jobEditView, arguments: ride);
              }
            : null,
        onDeletePressed: isCreatedByMe
            ? () {
                showDeleteDialog(jobId: ride.id);
              }
            : null,
        onAcceptApplicant: isCreatedByMe && ride.hasApplicants
            ? () {
                approveApplicant(jobId: ride.id);
              }
            : null,
        onRejectApplicant: isCreatedByMe && ride.hasApplicants
            ? () {
                rejectApplicant(jobId: ride.id);
              }
            : null,
        onCancelJob: isCreatedByMe
            ? () {
                cancelJob(jobId: ride.id);
              }
            : null,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  Future<void> openRideBottomSheet(String jobId) async {
    if (jobId.isEmpty) return;
    if (_currentlyOpeningJobId == jobId) {
      debugPrint("ℹ️ openRideBottomSheet already in progress for: $jobId");
      return;
    }
    _currentlyOpeningJobId = jobId;

    try {
      RideData? targetRide;
      bool isPast = false;

      // 1. Check in loaded upcomingRides
      targetRide = upcomingRides.firstWhereOrNull((r) => r.id == jobId);

      // 2. Check in loaded pastRides
      if (targetRide == null) {
        targetRide = pastRides.firstWhereOrNull((r) => r.id == jobId);
        if (targetRide != null) {
          isPast = true;
        }
      }

      // 3. If not in memory yet, fetch directly from API
      if (targetRide == null) {
        try {
          final response = await _jobRepo.getJobById(jobId: jobId);
          if (response.statusCode == 200 || response.statusCode == 201) {
            if (response.data != null &&
                response.data['data'] != null &&
                response.data['data'] is Map<String, dynamic>) {
              targetRide = RideData.fromJson(response.data['data']);
              final st =
                  (targetRide.status ?? targetRide.rideStatus ?? '').toUpperCase();
              isPast = (st == 'COMPLETED' || st == 'CANCELLED');
            }
          }
        } catch (e) {
          debugPrint("❌ Error fetching job by id ($jobId) for bottom sheet: $e");
        }
      }

      if (targetRide != null) {
        // Ensure the matching tab is selected
        if (isPast && selectedTab.value != 1) {
          selectedTab.value = 1;
        } else if (!isPast && selectedTab.value != 0) {
          selectedTab.value = 0;
        }

        final myId = Get.isRegistered<UserService>()
            ? Get.find<UserService>().userId
            : "";
        final isCreatedByMe = targetRide.isCreatedBy(myId);

        showRideDetailSheet(
          targetRide,
          isPast: isPast,
          isCreatedByMe: isCreatedByMe,
        );
      } else {
        debugPrint("⚠️ Ride not found with ID: $jobId");
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_currentlyOpeningJobId == jobId) {
          _currentlyOpeningJobId = null;
        }
      });
    }
  }
}
