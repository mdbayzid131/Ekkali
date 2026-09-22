import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/repositories/job_repository.dart';

import 'package:moeb_26/modules/rides/controllers/rides_controller.dart';

class RideCompletedController extends GetxController {
  final JobRepo _jobRepo = Get.find<JobRepo>();

  final RxInt rating = 0.obs;
  final RxString feedback = "".obs;
  final TextEditingController feedbackController = TextEditingController();
  final RxBool isLoading = false.obs;

  void updateRating(int value) {
    rating.value = value;
  }

  Future<void> submitReview() async {
    final dynamic ride = Get.arguments;
    String jobId = "";
    if (ride is String) {
      jobId = ride;
    } else if (ride is Map) {
      jobId = (ride['jobId'] ?? ride['id'] ?? ride['_id'] ?? "").toString();
    } else if (ride != null) {
      try {
        jobId = (ride.id ?? "").toString();
      } catch (_) {}
    }

    if (jobId.isEmpty) {
      Helpers.showCustomSnackBar("Job ID not found", isError: true);
      return;
    }

    if (rating.value == 0) {
      Helpers.showCustomSnackBar("Please select a rating (1-5 stars)", isError: true);
      return;
    }

    try {
      isLoading.value = true;
      final response = await _jobRepo.submitReview(
        jobId: jobId,
        rating: rating.value,
        comment: feedback.value.trim().isEmpty ? null : feedback.value.trim(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showCustomSnackBar(
          "Review submitted successfully",
          isError: false,
        );
        _navigateBack();
      } else {
        Helpers.showCustomSnackBar(
          response.data['message'] ?? "Failed to submit review",
          isError: true,
        );
      }
    } on dio.DioException catch (e) {
      Helpers.showCustomSnackBar(
        e.response?.data['message'] ?? "Error submitting review",
        isError: true,
      );
    } catch (e) {
      Helpers.showCustomSnackBar("Something went wrong", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void skipReview() {
    _navigateBack();
  }

  void _navigateBack() {
    // Refresh rides in controller if present
    try {
      if (Get.isRegistered<RidesController>()) {
        Get.find<RidesController>().refreshCurrentTab();
      }
    } catch (_) {}

    // Directly navigate to the Rides Tab (index 1) in BottomNavBar
    Get.offAllNamed(Routes.bottomNabbarView, arguments: 1);
  }

  @override
  void onClose() {
    feedbackController.dispose();
    super.onClose();
  }
}
