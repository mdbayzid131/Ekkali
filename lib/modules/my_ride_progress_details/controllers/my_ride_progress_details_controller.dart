import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/my_rides_model.dart';
import 'package:moeb_26/data/repositories/job_repository.dart';
import 'package:moeb_26/modules/rides/controllers/rides_controller.dart';

class MyRideProgressDetailsController extends GetxController {
  final JobRepo _jobRepo = Get.find<JobRepo>();
  SocketService? _socketService;

  var isLoading = false.obs;
  var currentRideStatus = "".obs;
  final Rx<RideData?> rideDetails = Rx<RideData?>(null);
  String? _initializedRideId;
  final List<Worker> _socketWorkers = [];

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<SocketService>()) {
      _socketService = Get.find<SocketService>();
      _setupSocketListeners();
    }
  }

  void _setupSocketListeners() {
    if (_socketService == null) return;

    // 1. Listen for Ride Status Updates (RIDE_STATUS_UPDATED)
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

          if (targetJobId == _initializedRideId && newStatus != null) {
            currentRideStatus.value = newStatus;
            debugPrint("✨ MyRideProgressDetailsController: Live ride status updated to $newStatus");
          }
        } catch (e) {
          debugPrint("❌ MyRideProgressDetailsController: Error handling RIDE_STATUS_UPDATED: $e");
        }
      }),
    );

    // 2. Listen for Job Cancellation (JOB_CANCELLED)
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

          if (targetJobId == _initializedRideId) {
            currentRideStatus.value = "CANCELLED";
            Helpers.showCustomSnackBar(
              "This ride has been cancelled by the creator.",
              isError: true,
            );
            debugPrint("🚨 MyRideProgressDetailsController: Live job cancelled");
          }
        } catch (e) {
          debugPrint("❌ MyRideProgressDetailsController: Error handling JOB_CANCELLED: $e");
        }
      }),
    );
  }

  void setInitialStatus(String? rideId, String? status) {
    if (_initializedRideId != rideId) {
      if (_initializedRideId != null && _initializedRideId!.isNotEmpty) {
        _socketService?.leaveJob(_initializedRideId!);
      }
      _initializedRideId = rideId;
      currentRideStatus.value = status ?? "PENDING";
      if (rideId != null && rideId.isNotEmpty) {
        _socketService?.joinJob(rideId);
      }
    }
  }

  Future<void> fetchJobDetails(String jobId) async {
    if (jobId.isEmpty) return;
    try {
      isLoading.value = true;
      final response = await _jobRepo.getJobById(jobId: jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null &&
            response.data is Map<String, dynamic> &&
            response.data['data'] != null &&
            response.data['data'] is Map<String, dynamic>) {
          final fullRide = RideData.fromJson(response.data['data']);
          rideDetails.value = fullRide;
          final status = fullRide.rideStatus ?? fullRide.status ?? "PENDING";
          currentRideStatus.value = status;
        }
      }
    } catch (e) {
      debugPrint("Error fetching ride details from API: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStatus(
    String jobId,
    String nextStatus, {
    dynamic rideData,
  }) async {
    currentRideStatus.value = nextStatus;

    try {
      await _jobRepo.updateRideStatus(jobId: jobId, rideStatus: nextStatus);
    } catch (e) {
      debugPrint("Error updating ride status on server: $e");
    }

    try {
      if (Get.isRegistered<RidesController>()) {
        Get.find<RidesController>().refreshCurrentTab();
      }
    } catch (_) {}

    if (nextStatus == "FINISHED") {
      Get.toNamed(
        Routes.rideCompletedView,
        arguments: rideData ?? {"id": jobId},
      );
    } else {
      Helpers.showCustomSnackBar(
        "Ride status updated to $nextStatus",
        isError: false,
      );
    }
  }

  @override
  void onClose() {
    if (_initializedRideId != null && _initializedRideId!.isNotEmpty) {
      _socketService?.leaveJob(_initializedRideId!);
    }
    for (var worker in _socketWorkers) {
      worker.dispose();
    }
    _socketWorkers.clear();
    super.onClose();
  }
}
