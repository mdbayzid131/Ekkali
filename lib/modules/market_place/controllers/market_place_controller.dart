import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/utils/media_picker_helper.dart';
import 'package:moeb_26/core/services/marketplace_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/market_place_model.dart';
import 'package:moeb_26/modules/my_items/controllers/my_items_controller.dart'
    as my_items;

class MarketplaceController extends GetxController {
  final MarketplaceService _marketplaceService = Get.put(MarketplaceService());

  var allItems = <ItemData>[].obs;
  var filteredItems = <ItemData>[].obs;
  var isLoading = false.obs;
  var isLoadMore = false.obs;
  var currentPage = 1;
  var totalPage = 1;
  String currentQuery = "";

  final ScrollController scrollController = ScrollController();

  // Sell Item Form States
  final RxString selectedCondition = "".obs;
  final List<String> conditions = [
    "New",
    "Used", // Changed to match API/Postman
    "Refurbished",
  ];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final RxList<File> selectedImages = <File>[].obs;
  final RxList<String> existingImagePaths = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
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
      loadMoreItems();
    }
  }

  Future<void> fetchItems({String? query}) async {
    try {
      isLoading.value = true;
      currentPage = 1;
      currentQuery = query ?? "";
      final response = await _marketplaceService.getAllItems(
        searchTerm: currentQuery.isNotEmpty ? currentQuery : null,
        page: currentPage,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final marketplaceModel = MarketplaceModel.fromJson(response.data);
        final items = marketplaceModel.data ?? [];
        totalPage = marketplaceModel.pagination?.totalPage ?? 1;

        allItems.assignAll(items);
        filteredItems.assignAll(items);
      }
    } catch (e) {
      print("Error fetching items: $e");
      Get.snackbar(
        "Error",
        "Failed to fetch marketplace items",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreItems() async {
    try {
      isLoadMore.value = true;
      currentPage++;
      final response = await _marketplaceService.getAllItems(
        searchTerm: currentQuery.isNotEmpty ? currentQuery : null,
        page: currentPage,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final marketplaceModel = MarketplaceModel.fromJson(response.data);
        final items = marketplaceModel.data ?? [];

        allItems.addAll(items);
        filteredItems.assignAll(allItems);
      }
    } catch (e) {
      print("Error loading more items: $e");
      currentPage--; // Reset page on error
    } finally {
      isLoadMore.value = false;
    }
  }

  void searchItems(String query) {
    // We can either filter locally or fetch from API
    // Let's fetch from API as it has search support
    fetchItems(query: query);
  }

  Future<void> pickImages(BuildContext context) async {
    final List<File>? images = await MediaPickerHelper.pickMultiImages(context);
    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        final compressed = await Helpers.compressImage(image);
        selectedImages.add(compressed);
      }
    }
  }

  void updateCondition(String condition) {
    if (selectedCondition.value == condition) {
      selectedCondition.value = "";
    } else {
      selectedCondition.value = condition;
    }
  }

  Future<void> listItem({String? editItemId}) async {
    if (titleController.text.isEmpty ||
        priceController.text.isEmpty ||
        locationController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill title, price, and location",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final response = editItemId == null
          ? await _marketplaceService.createItem(
              title: titleController.text,
              price: priceController.text,
              condition: selectedCondition.value.isNotEmpty
                  ? selectedCondition.value
                  : null,
              location: locationController.text,
              description: descriptionController.text.isNotEmpty
                  ? descriptionController.text
                  : null,
              photos: selectedImages.isNotEmpty
                  ? selectedImages.toList()
                  : null,
            )
          : await _marketplaceService.updateItem(
              itemId: editItemId,
              title: titleController.text,
              price: priceController.text,
              condition: selectedCondition.value.isNotEmpty
                  ? selectedCondition.value
                  : null,
              location: locationController.text,
              description: descriptionController.text.isNotEmpty
                  ? descriptionController.text
                  : null,
              photos: selectedImages.isNotEmpty
                  ? selectedImages.toList()
                  : null,
              // status could also be updated here if needed
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar(
          "Success",
          editItemId == null
              ? "Item listed successfully!"
              : "Item updated successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff1A1A1A),
          colorText: Colors.white,
        );
        clearFields();
        fetchItems(); // Refresh the general list

        // Also refresh My Items list if that controller is active
        if (Get.isRegistered<my_items.MyItemsController>()) {
          Get.find<my_items.MyItemsController>().fetchMyItems();
        }
      } else {
        Get.snackbar(
          "Error",
          "Failed to ${editItemId == null ? 'list' : 'update'} item: ${response.statusMessage ?? 'Unknown error'}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Error processing item: $e");
      Get.snackbar(
        "Error",
        "An error occurred while ${editItemId == null ? 'listing' : 'updating'} the item",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    titleController.clear();
    priceController.clear();
    locationController.clear();
    descriptionController.clear();
    selectedImages.clear();
    existingImagePaths.clear();
    selectedCondition.value = "";
  }

  void prefillForEdit(
    String title,
    String price,
    String location,
    String condition,
    String description,
    List<String> photos,
  ) {
    titleController.text = title;
    priceController.text = price;
    locationController.text = location;
    descriptionController.text = description;
    existingImagePaths.assignAll(photos);
    if (condition.isNotEmpty && conditions.contains(condition)) {
      selectedCondition.value = condition;
    } else {
      selectedCondition.value = "";
    }
    selectedImages.clear();
  }
}
