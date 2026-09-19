import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
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

  // Strict Cursor Pagination
  String? nextCursor;
  bool hasMore = true;
  String currentQuery = "";
  final RxString selectedFilterCondition = "".obs;

  final ScrollController scrollController = ScrollController();

  // Sell Item Form States
  final RxString selectedCondition = "".obs;
  final List<String> conditions = [
    "New",
    "Used",
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
    fetchItems();
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
      loadMoreItems();
    }
  }

  Future<void> fetchItems({String? query, String? condition}) async {
    try {
      isLoading.value = true;
      nextCursor = null;
      hasMore = true;
      currentQuery = query ?? currentQuery;
      final cond = condition ?? (selectedFilterCondition.value.isNotEmpty ? selectedFilterCondition.value : null);

      final response = await _marketplaceService.getAllItems(
        searchTerm: currentQuery.isNotEmpty ? currentQuery : null,
        condition: cond,
        limit: 10,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final marketplaceModel = MarketplaceModel.fromJson(response.data);
        final items = marketplaceModel.data ?? [];

        nextCursor = marketplaceModel.cursor?.nextCursor;
        hasMore = marketplaceModel.cursor?.hasMore ?? (nextCursor != null && nextCursor!.isNotEmpty);

        allItems.assignAll(items);
        filteredItems.assignAll(items);
      }
    } catch (e) {
      print("Error fetching items: $e");
      Helpers.showCustomSnackBar("Failed to fetch marketplace items", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreItems() async {
    if (!hasMore || isLoadMore.value || nextCursor == null || nextCursor!.isEmpty) return;

    try {
      isLoadMore.value = true;
      final cond = selectedFilterCondition.value.isNotEmpty ? selectedFilterCondition.value : null;

      final response = await _marketplaceService.getAllItems(
        searchTerm: currentQuery.isNotEmpty ? currentQuery : null,
        condition: cond,
        cursor: nextCursor,
        limit: 10,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final marketplaceModel = MarketplaceModel.fromJson(response.data);
        final items = marketplaceModel.data ?? [];

        nextCursor = marketplaceModel.cursor?.nextCursor;
        hasMore = marketplaceModel.cursor?.hasMore ?? (nextCursor != null && nextCursor!.isNotEmpty);

        allItems.addAll(items);
        filteredItems.assignAll(allItems);
      }
    } catch (e) {
      print("Error loading more items: $e");
    } finally {
      isLoadMore.value = false;
    }
  }

  void searchItems(String query) {
    currentQuery = query;
    fetchItems(query: query);
  }

  void filterByCondition(String condition) {
    if (selectedFilterCondition.value == condition) {
      selectedFilterCondition.value = "";
    } else {
      selectedFilterCondition.value = condition;
    }
    fetchItems(condition: selectedFilterCondition.value.isNotEmpty ? selectedFilterCondition.value : null);
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

  Future<void> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        final compressed = await Helpers.compressImage(File(image.path));
        selectedImages.add(compressed);
      }
    } catch (e) {
      Helpers.error('Error picking from camera: $e');
      Helpers.showCustomSnackBar(
        'Could not open camera. Please check app permissions in settings.',
        isError: true,
      );
    }
  }

  void showPhotoSelectionDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: const Border(
            top: BorderSide(color: Color(0xFF282828), width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Text(
                'Add Photo',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        takePhoto();
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFF2C2C2C)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.primaryColor,
                              size: 28.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Camera',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        pickImages(context);
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFF2C2C2C)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: AppColors.primaryColor,
                              size: 28.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Gallery',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void updateCondition(String condition) {
    if (selectedCondition.value == condition) {
      selectedCondition.value = "";
    } else {
      selectedCondition.value = condition;
    }
  }

  Future<void> listItem({String? editItemId}) async {
    if (titleController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty) {
      Helpers.showCustomSnackBar("Please fill title, price, and location", isError: true);
      return;
    }

    try {
      isLoading.value = true;
      final response = editItemId == null
          ? await _marketplaceService.createItem(
              title: titleController.text.trim(),
              price: priceController.text.trim(),
              condition: selectedCondition.value.isNotEmpty
                  ? selectedCondition.value
                  : null,
              location: locationController.text.trim(),
              description: descriptionController.text.trim().isNotEmpty
                  ? descriptionController.text.trim()
                  : null,
              photos: selectedImages.isNotEmpty
                  ? selectedImages.toList()
                  : null,
            )
          : await _marketplaceService.updateItem(
              itemId: editItemId,
              title: titleController.text.trim(),
              price: priceController.text.trim(),
              condition: selectedCondition.value.isNotEmpty
                  ? selectedCondition.value
                  : null,
              location: locationController.text.trim(),
              description: descriptionController.text.trim().isNotEmpty
                  ? descriptionController.text.trim()
                  : null,
              photos: selectedImages.isNotEmpty
                  ? selectedImages.toList()
                  : null,
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Helpers.showCustomSnackBar(
          editItemId == null
              ? "Item listed successfully!"
              : "Item updated successfully!",
          isError: false,
        );
        clearFields();
        fetchItems(); // Refresh the general marketplace list

        // Also refresh My Items list if that controller is active
        if (Get.isRegistered<my_items.MyItemsController>()) {
          Get.find<my_items.MyItemsController>().fetchMyItems();
        }
      } else {
        Helpers.showCustomSnackBar(
          "Failed to ${editItemId == null ? 'list' : 'update'} item: ${response.statusMessage ?? 'Unknown error'}",
          isError: true,
        );
      }
    } catch (e) {
      print("Error processing item: $e");
      Helpers.showCustomSnackBar(
        "An error occurred while ${editItemId == null ? 'listing' : 'updating'} the item",
        isError: true,
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
