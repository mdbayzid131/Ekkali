import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/services/job_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/my_jobs_model.dart';
import 'package:moeb_26/data/repositories/job_repository.dart';
import 'package:moeb_26/modules/rides/controllers/rides_controller.dart';

class MyJobProgressDetailsController extends GetxController {
  final JobService _jobService = Get.find<JobService>();
  final JobRepo _jobRepo = Get.find<JobRepo>();

  final Rxn<JobData> myJobView = Rxn<JobData>();
  final RxBool isJobDetailsLoading = false.obs;
  final RxBool isActionLoading = false.obs;

  Future<void> fetchJobDetails({required String jobId}) async {
    try {
      debugPrint(
        "🔍 MyJobProgressDetailsController: Fetching details for jobId: $jobId",
      );
      isJobDetailsLoading.value = true;
      if (myJobView.value?.id != jobId) {
        myJobView.value = null;
      }

      final response = await _jobService.getJobById(jobId: jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['data'] != null) {
          final updatedJob = JobData.fromJson(response.data['data']);
          debugPrint(
            "✅ MyJobProgressDetailsController: Job details fetched. Status: ${updatedJob.status}, RideStatus: ${updatedJob.rideStatus}",
          );
          myJobView.value = updatedJob;
        }
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to fetch job details.')
            : 'Failed to fetch job details.';
        debugPrint("❌ MyJobProgressDetailsController: API Error: $message");
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Failed to fetch job details.';
      debugPrint("❌ MyJobProgressDetailsController: Dio Error: $message");
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      debugPrint("❌ MyJobProgressDetailsController: General Error: $e");
    } finally {
      isJobDetailsLoading.value = false;
    }
  }

  Future<bool> cancelJobOffer({required String jobId}) async {
    try {
      isActionLoading.value = true;
      final response = await _jobRepo.cancelJobOffer(jobId: jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (Get.isRegistered<RidesController>()) {
          Get.find<RidesController>().refreshCurrentTab();
        }
        return true;
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to cancel job.')
            : 'Failed to cancel job.';
        Helpers.showCustomSnackBar(message, isError: true);
        return false;
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to cancel job.';
      Helpers.showCustomSnackBar(message, isError: true);
      return false;
    } catch (e) {
      debugPrint("Error canceling job: $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> deleteJob({required String jobId}) async {
    try {
      isActionLoading.value = true;
      final response = await _jobRepo.deleteJob(jobId: jobId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (Get.isRegistered<RidesController>()) {
          Get.find<RidesController>().refreshCurrentTab();
        }
        return true;
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to delete job.')
            : 'Failed to delete job.';
        Helpers.showCustomSnackBar(message, isError: true);
        return false;
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to delete job.';
      Helpers.showCustomSnackBar(message, isError: true);
      return false;
    } catch (e) {
      debugPrint("Error deleting job: $e");
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }
}
