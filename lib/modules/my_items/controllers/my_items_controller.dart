import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/services/marketplace_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/my_items_model.dart';
import 'package:moeb_26/modules/market_place/controllers/market_place_controller.dart';

class MyItemsController extends GetxController {
  final MarketplaceService _marketplaceService = Get.put(MarketplaceService());

  var myItems = <MyItemsModel>[].obs;
  var isLoading = false.obs;
  var isLoadMore = false.obs;

  // Strict Cursor Pagination
  String? nextCursor;
  bool hasMore = true;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchMyItems();
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
        hasMore &&
        nextCursor != null &&
        nextCursor!.isNotEmpty) {
      loadMoreMyItems();
    }
  }

  Future<void> fetchMyItems() async {
    try {
      isLoading.value = true;
      nextCursor = null;
      hasMore = true;

      final response = await _marketplaceService.getMyItems(
        limit: 10,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final myItemsResponse = MyItemsResponse.fromJson(response.data);
        final items = myItemsResponse.data ?? [];

        nextCursor = myItemsResponse.cursor?.nextCursor;
        hasMore = myItemsResponse.cursor?.hasMore ?? (nextCursor != null && nextCursor!.isNotEmpty);

        myItems.assignAll(items);
      }
    } catch (e) {
      print("Error fetching my items: $e");
      Helpers.showCustomSnackBar("Failed to fetch your items", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreMyItems() async {
    if (!hasMore || isLoadMore.value || nextCursor == null || nextCursor!.isEmpty) return;

    try {
      isLoadMore.value = true;

      final response = await _marketplaceService.getMyItems(
        cursor: nextCursor,
        limit: 10,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final myItemsResponse = MyItemsResponse.fromJson(response.data);
        final items = myItemsResponse.data ?? [];

        nextCursor = myItemsResponse.cursor?.nextCursor;
        hasMore = myItemsResponse.cursor?.hasMore ?? (nextCursor != null && nextCursor!.isNotEmpty);

        myItems.addAll(items);
      }
    } catch (e) {
      print("Error loading more items: $e");
    } finally {
      isLoadMore.value = false;
    }
  }

  Future<void> markAsSold(String id) async {
    try {
      final response = await _marketplaceService.markItemAsSold(id);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final index = myItems.indexWhere((item) => item.id == id);
        if (index != -1) {
          final old = myItems[index];
          myItems[index] = MyItemsModel(
            id: old.id,
            name: old.name,
            price: old.price,
            rating: old.rating,
            imagePath: old.imagePath,
            condition: old.condition,
            status: "SOLD",
            location: old.location,
            description: old.description,
            photos: old.photos,
            createdAt: old.createdAt,
          );
        }
        Helpers.showCustomSnackBar("Item marked as sold!", isError: false);

        if (Get.isRegistered<MarketplaceController>()) {
          Get.find<MarketplaceController>().fetchItems();
        }
      } else {
        Helpers.showCustomSnackBar("Failed to mark item as sold", isError: true);
      }
    } catch (e) {
      print("Error marking item as sold: $e");
      Helpers.showCustomSnackBar("An error occurred while updating status", isError: true);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      final response = await _marketplaceService.deleteItem(id);

      if (response.statusCode == 200 || response.statusCode == 201) {
        myItems.removeWhere((item) => item.id == id);
        Helpers.showCustomSnackBar("Item deleted successfully", isError: false);

        if (Get.isRegistered<MarketplaceController>()) {
          Get.find<MarketplaceController>().fetchItems();
        }
      } else {
        Helpers.showCustomSnackBar("Failed to delete item", isError: true);
      }
    } catch (e) {
      print("Error deleting item: $e");
      Helpers.showCustomSnackBar("An error occurred while deleting", isError: true);
    }
  }
}
