import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:moeb_26/Data/models/finish_rides_model.dart';
import 'package:moeb_26/Data/models/upcoming_rides_model.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/repositories/job_repository.dart';

class RidesController extends GetxController {
  final JobRepo _jobRepo = Get.find<JobRepo>();
  RxBool isLoadingList = false.obs;
  RxBool isLoadMore = false.obs;

  var selectedTab = 0.obs; // Default to Upcoming

  // Pagination states
  int upcomingPage = 1;
  int upcomingTotalPage = 1;
  int pastPage = 1;
  int pastTotalPage = 1;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Map && Get.arguments.containsKey('ridesTab')) {
      selectedTab.value = Get.arguments['ridesTab'];
    }
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
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
        if (upcomingPage < upcomingTotalPage) {
          loadMoreUpcomingJobs();
        }
      } else if (selectedTab.value == 1 && pastPage < pastTotalPage) {
        loadMorePastJobs();
      }
    }
  }

  RxList<UpcomingRideData> upcomingRides = <UpcomingRideData>[].obs;
  RxList<FinishRideData> pastRides = <FinishRideData>[].obs;

  Future<void> fetchUpcomingJobs() async {
    // Static UI mode - API call bypassed
  }

  Future<void> loadMoreUpcomingJobs() async {
    // Static UI mode - API call bypassed
  }

  Future<void> fetchPastJobs() async {
    // Static UI mode - API call bypassed
  }

  Future<void> loadMorePastJobs() async {
    // Static UI mode - API call bypassed
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  Future<void> refreshCurrentTab() async {
    // Static UI mode - API call bypassed
  }
}
