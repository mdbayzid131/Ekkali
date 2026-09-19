import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/services/dealsItems_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/deals_model.dart';

class DealsController extends GetxController {
  final DealsService _dealsService = Get.put(DealsService());

  // Reactive list of deals
  final RxList<DealsItem> dealsList = <DealsItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadMore = false.obs;
  int currentPage = 1;
  int totalPage = 1;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchDeals();
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
        !isLoading.value &&
        !isLoadMore.value &&
        currentPage < totalPage) {
      loadMoreDeals();
    }
  }

  Future<void> fetchDeals() async {
    try {
      isLoading.value = true;
      currentPage = 1;
      final response = await _dealsService.getActiveDeals(page: currentPage);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dealsResponse = DealsResponse.fromJson(response.data);
        final items = dealsResponse.data ?? [];
        totalPage = dealsResponse.pagination?.totalPage ?? 1;
        dealsList.assignAll(items);
      }
    } catch (e) {
      print("Error fetching deals: $e");
      Helpers.showCustomSnackBar("Failed to fetch deals", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreDeals() async {
    try {
      isLoadMore.value = true;
      currentPage++;
      final response = await _dealsService.getActiveDeals(page: currentPage);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dealsResponse = DealsResponse.fromJson(response.data);
        final items = dealsResponse.data ?? [];
        dealsList.addAll(items);
      }
    } catch (e) {
      print("Error loading more deals: $e");
      currentPage--; // Reset page on error
    } finally {
      isLoadMore.value = false;
    }
  }

  // Copy promo code to clipboard
  void copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    Helpers.showCustomSnackBar(
      "Promo code $code copied to clipboard",
      isError: false,
      duration: const Duration(seconds: 2),
    );
  }
}
