import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../rides/controllers/rides_controller.dart';
import '../../jobs_offers/controllers/Job_offer_controller.dart';
import '../../chat/controllers/chat_controller.dart';

class NavigationController extends GetxController {
  var currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is int) {
      currentIndex.value = Get.arguments;
    } else if (Get.arguments is Map &&
        Get.arguments.containsKey('bottomIndex')) {
      currentIndex.value = Get.arguments['bottomIndex'];
    }

    if (currentIndex.value == 1) {
      try {
        if (Get.isRegistered<RidesController>()) {
          Get.find<RidesController>().refreshCurrentTab();
        }
      } catch (_) {}
    }
  }

  void changeIndex(int index) {
    currentIndex.value = index;
    if (index == 0) {
      // Index 0 is JobOfferPage
      try {
        if (Get.isRegistered<JobOfferController>()) {
          Get.find<JobOfferController>().fetchJobOffers(isRefresh: true);
        }
      } catch (e) {
        debugPrint("NavigationController fetchJobOffers error: $e");
      }
    } else if (index == 1) {
      // Index 1 is RidesPage
      try {
        Get.find<RidesController>().refreshCurrentTab();
      } catch (e) {
        debugPrint("NavigationController refreshCurrentTab error: $e");
      }
    } else if (index == 2) {
      // Index 2 is ChatPage
      try {
        Get.find<ChatController>().fetchChats();
      } catch (e) {
        debugPrint("NavigationController fetchChats error: $e");
      }
    } else if (index == 4) {
      // Index 4 is Favorite Drivers page
      // Local state is used, no API call needed
    }
  }
}
