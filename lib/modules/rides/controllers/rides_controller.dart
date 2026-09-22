import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/my_rides_model.dart';
import 'package:moeb_26/data/repositories/job_repository.dart';

class RidesController extends GetxController {
  final JobRepo _jobRepo = Get.find<JobRepo>();
  SocketService? _socketService;

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
}
