import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/data/models/account_status.dart';
import 'package:moeb_26/modules/jobs_offers/controllers/Job_offer_controller.dart';
import 'package:moeb_26/modules/market_place/controllers/market_place_controller.dart';

class AccountStatusSync {
  static Future<void> apply(dynamic data) async {
    try {
      if (data is! Map) return;
      final restricted = AccountStatus.restrictionFrom(data);
      if (restricted == null) return;
      final user = Get.isRegistered<UserService>()
          ? Get.find<UserService>()
          : null;
      final changed = user?.applyRealtimeRestriction(restricted) ?? false;

      if (changed) {
        if (restricted && Get.isBottomSheetOpen == true) Get.back();
        // A lazy controller fetches in onInit; do not fetch it a second time.
        if (Get.isRegistered<JobOfferController>()) {
          final needsInitialFetch = Get.isPrepared<JobOfferController>();
          final controller = Get.find<JobOfferController>();
          if (!needsInitialFetch) controller.fetchJobOffers(isRefresh: true);
        }
        if (Get.isRegistered<MarketplaceController>()) {
          final needsInitialFetch = Get.isPrepared<MarketplaceController>();
          final controller = Get.find<MarketplaceController>();
          if (!needsInitialFetch) controller.fetchItems();
        }
      }
      // Persist even when UserService is not registered yet or status is unchanged.
      await StorageService.setBool(StorageConstants.isRestricted, restricted);
    } catch (e) {
      debugPrint('AccountStatusSync: Failed to apply account status: $e');
    }
  }
}
