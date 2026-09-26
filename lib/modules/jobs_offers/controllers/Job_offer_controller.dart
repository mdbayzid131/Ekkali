import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/job_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/data/models/job_offer_model.dart';

class JobOfferController extends GetxController {
  late final JobService _jobService;
  SocketService? _socketService;

  final RxList<JobOfferModel> jobOffers = <JobOfferModel>[].obs;
  final RxMap<String, List<JobOfferModel>> groupedJobOffers =
      <String, List<JobOfferModel>>{}.obs;

  final RxBool isLoading = false.obs;
  final RxBool isApplying = false.obs;
  final RxString errorMessage = ''.obs;

  final List<Worker> _socketWorkers = [];

  @override
  void onInit() {
    super.onInit();
    _jobService = Get.isRegistered<JobService>()
        ? Get.find<JobService>()
        : Get.put(JobService());
    if (Get.isRegistered<SocketService>()) {
      _socketService = Get.find<SocketService>();
      _setupSocketListeners();
    }
    fetchJobOffers();
  }

  void _setupSocketListeners() {
    if (_socketService == null) return;

    // 1. Listen for new job creations (JOB_CREATED)
    _socketWorkers.add(
      ever(_socketService!.lastCreatedJob, (data) {
        if (data == null) return;
        try {
          Map<String, dynamic>? jobMap;
          if (data is Map<String, dynamic>) {
            if (data.containsKey('job') &&
                data['job'] is Map<String, dynamic>) {
              jobMap = data['job'];
            } else if (data.containsKey('data') &&
                data['data'] is Map<String, dynamic>) {
              jobMap = data['data'];
            } else {
              jobMap = data;
            }
          }

          if (jobMap != null) {
            final newJob = JobOfferModel.fromJson(jobMap);
            final currentUserId = Get.isRegistered<UserService>()
                ? Get.find<UserService>().userId
                : '';

            // Ignore jobs created by the current logged-in user
            if (currentUserId.isNotEmpty &&
                newJob.createdBy != null &&
                newJob.createdBy == currentUserId) {
              debugPrint(
                "🚫 JobOfferController: Ignored self-created job from feed [${newJob.id}]",
              );
              return;
            }

            if (newJob.id.isNotEmpty &&
                !jobOffers.any((j) => j.id == newJob.id)) {
              jobOffers.insert(0, newJob);
              _groupOffersByDate(jobOffers);
              debugPrint(
                "✨ JobOfferController: Real-time JOB_CREATED added [${newJob.id}]",
              );
            }
          }
        } catch (e) {
          debugPrint(
            "❌ JobOfferController: Error parsing JOB_CREATED data: $e",
          );
        }
      }),
    );

    // 2. Listen for removed jobs from feed (JOB_REMOVED_FROM_FEED)
    _socketWorkers.add(
      ever(_socketService!.lastRemovedJobFeed, (data) {
        if (data == null) return;
        try {
          String? targetJobId;
          if (data is Map) {
            targetJobId =
                data['jobId']?.toString() ??
                data['id']?.toString() ??
                data['_id']?.toString();
          } else if (data is String) {
            targetJobId = data;
          }

          if (targetJobId != null && targetJobId.isNotEmpty) {
            final initialLength = jobOffers.length;
            jobOffers.removeWhere((item) => item.id == targetJobId);
            if (jobOffers.length != initialLength) {
              _groupOffersByDate(jobOffers);
              debugPrint(
                "🗑️ JobOfferController: Real-time JOB_REMOVED_FROM_FEED removed [$targetJobId]",
              );
            }
          }
        } catch (e) {
          debugPrint(
            "❌ JobOfferController: Error parsing JOB_REMOVED_FROM_FEED data: $e",
          );
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
    super.onClose();
  }

  Future<void> fetchJobOffers({bool isRefresh = false}) async {
    if (!isRefresh) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final response = await _jobService.getAllJobOffers();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic rawData = response.data?['data'];
        final List<dynamic> list = (rawData is List) ? rawData : [];
        final currentUserId = Get.isRegistered<UserService>()
            ? Get.find<UserService>().userId
            : '';

        final items = list
            .map((item) {
              try {
                return JobOfferModel.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                debugPrint("Error parsing JobOffer item: $e");
                return null;
              }
            })
            .whereType<JobOfferModel>()
            .where(
              (j) =>
                  currentUserId.isEmpty ||
                  j.createdBy == null ||
                  j.createdBy != currentUserId,
            )
            .toList();

        jobOffers.assignAll(items);
        _groupOffersByDate(items);
      } else {
        errorMessage.value =
            response.data?['message']?.toString() ?? 'Failed to load offers.';
      }
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message']?.toString() ?? 'Failed to load offers.';
      debugPrint("Dio error fetching job offers: $e");
    } catch (e) {
      errorMessage.value = 'Something went wrong while loading offers.';
      debugPrint("Error fetching job offers: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _groupOffersByDate(List<JobOfferModel> items) {
    final Map<String, List<JobOfferModel>> groups = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final job in items) {
      String header;
      DateTime? parsed;

      if (job.asap) {
        parsed = job.createdAt ?? DateTime.now();
      } else if (job.date != null) {
        parsed = job.date;
      } else if (job.createdAt != null) {
        parsed = job.createdAt;
      }

      if (parsed != null) {
        final localDate = parsed.toLocal();
        final targetDate = DateTime(
          localDate.year,
          localDate.month,
          localDate.day,
        );
        if (targetDate == today) {
          header = "Today, ${DateFormat('MMM dd').format(localDate)}";
        } else if (targetDate == today.add(const Duration(days: 1))) {
          header = "Tomorrow, ${DateFormat('MMM dd').format(localDate)}";
        } else if (targetDate == today.subtract(const Duration(days: 1))) {
          header = "Yesterday, ${DateFormat('MMM dd').format(localDate)}";
        } else if (localDate.year != now.year) {
          header = DateFormat('EEE, MMM dd, yyyy').format(localDate);
        } else {
          header = DateFormat('EEE, MMM dd').format(localDate);
        }
      } else {
        header = 'Available Offers';
      }

      if (!groups.containsKey(header)) {
        groups[header] = [];
      }
      groups[header]!.add(job);
    }

    groupedJobOffers.assignAll(groups);
  }

  Future<void> applyToJob(JobOfferModel job) async {
    try {
      isApplying.value = true;

      final response = await _jobService.applyToJob(jobId: job.id);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(); // Close bottom sheet if open

        Helpers.showCustomSnackBar(
          response.data?['message']?.toString() ??
              'Applied to job successfully!',
          isError: false,
        );

        // Remove from list or refresh feed
        jobOffers.removeWhere((item) => item.id == job.id);
        _groupOffersByDate(jobOffers);

        // Navigate to Application Status / Review screen
        Get.toNamed(Routes.requestSubmittedView, arguments: job.toJson());
      } else {
        final message =
            response.data?['message']?.toString() ?? 'Failed to apply for job.';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ?? 'Failed to apply.';
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
      debugPrint("Error applying to job: $e");
    } finally {
      isApplying.value = false;
    }
  }
}
