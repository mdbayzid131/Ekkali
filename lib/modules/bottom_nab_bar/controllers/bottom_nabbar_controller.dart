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
    String? targetJobId;

    if (Get.arguments is int) {
      currentIndex.value = Get.arguments;
    } else if (Get.arguments is Map) {
      if (Get.arguments.containsKey('bottomIndex')) {
        currentIndex.value = Get.arguments['bottomIndex'];
      }
      targetJobId = Get.arguments['targetJobId']?.toString();
    }

    if (currentIndex.value == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final ridesCtrl = Get.isRegistered<RidesController>()
              ? Get.find<RidesController>()
              : Get.put(RidesController());
          ridesCtrl.refreshCurrentTab();
          if (targetJobId != null && targetJobId.isNotEmpty) {
            ridesCtrl.openRideBottomSheet(targetJobId);
          }
        } catch (e) {
          debugPrint("NavigationController onInit rides error: $e");
        }
      });
    } else if (currentIndex.value == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (Get.isRegistered<ChatController>()) {
            Get.find<ChatController>().fetchChats();
          }
        } catch (_) {}
      });
    }
  }

  void navigateToRidesTab({String? targetJobId}) {
    currentIndex.value = 1;
    final ridesCtrl = Get.isRegistered<RidesController>()
        ? Get.find<RidesController>()
        : Get.put(RidesController());
    ridesCtrl.refreshCurrentTab();
    if (targetJobId != null && targetJobId.isNotEmpty) {
      ridesCtrl.openRideBottomSheet(targetJobId);
    }
  }

  void navigateToChatTab() {
    currentIndex.value = 2;
    try {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().fetchChats();
      }
    } catch (e) {
      debugPrint("NavigationController navigateToChatTab error: $e");
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
        final ridesCtrl = Get.isRegistered<RidesController>()
            ? Get.find<RidesController>()
            : Get.put(RidesController());
        ridesCtrl.refreshCurrentTab();
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
