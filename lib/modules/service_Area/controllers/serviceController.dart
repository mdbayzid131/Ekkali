import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/services/serviceAreas_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/service_area_model.dart';

class ServiceAreaController extends GetxController {
  final ServiceAreaService _serviceAreasService = Get.put(ServiceAreaService());

  RxList<ServiceAreaModel> serviceAreas = <ServiceAreaModel>[].obs;
  var isLoading = false.obs;
  var isMoreLoading = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var limit = 10;

  final ScrollController scrollController = ScrollController();

  // Selected service area name
  var selectedAreaName = "".obs;
  var isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    serviceAreas.assignAll([
      ServiceAreaModel(id: '1', areaName: 'Miami, FL', city: 'Miami', status: 'ACTIVE', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ServiceAreaModel(id: '2', areaName: 'Fort Lauderdale, FL', city: 'Fort Lauderdale', status: 'ACTIVE', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ServiceAreaModel(id: '3', areaName: 'Palm Beach, FL', city: 'Palm Beach', status: 'ACTIVE', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ServiceAreaModel(id: '4', areaName: 'New York, NY', city: 'New York', status: 'ACTIVE', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ServiceAreaModel(id: '5', areaName: 'Los Angeles, CA', city: 'Los Angeles', status: 'ACTIVE', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    ]);
    _initCurrentServiceArea();
    scrollController.addListener(_onScroll);
  }

  void _initCurrentServiceArea() {
    // If the UserService has the profile data, we could pre-select it
    // For now, it will be updated when the user selects one
  }

  void selectServiceArea(String areaName) {
    selectedAreaName.value = areaName;
  }

  Future<void> updateServiceArea() async {
    if (selectedAreaName.value.isEmpty) {
      Helpers.showCustomSnackBar(
        "Please select a service area first",
        isError: true,
      );
      return;
    }

    try {
      isUpdating.value = true;
      final response = await _serviceAreasService.updateServiceArea(
        selectedAreaName.value,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(); // Go back immediately after success for snappy UX
        Helpers.showCustomSnackBar(
          "Service area updated successfully",
          isError: false,
        );

        try {
          Get.find<UserService>().fetchUserId();
        } catch (e) {
          debugPrint("Safe to ignore: User profile refresh failed $e");
        }
      } else {
        Helpers.showCustomSnackBar(
          response.data['message'] ?? "Failed to update service area",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Error updating service area: $e");
      Helpers.showCustomSnackBar(
        "Something went wrong while updating",
        isError: true,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _onScroll() {
    if (!scrollController.hasClients ||
        scrollController.positions.length != 1) {
      return Future.value();
    }
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoading.value &&
        !isMoreLoading.value &&
        currentPage.value < totalPages.value) {
      loadMoreServiceAreas();
    }
    return Future.value();
  }

  Future<void> fetchServiceAreas({bool isRefresh = false}) async {
    // If already loading, don't trigger again
    if (isLoading.value || isMoreLoading.value) return;

    if (isRefresh) {
      currentPage.value = 1;
    }

    try {
      if (currentPage.value == 1) {
        isLoading.value = true;
      } else {
        isMoreLoading.value = true;
      }

      debugPrint("Service Areas Request: Page ${currentPage.value}, Limit $limit");

      final response = await _serviceAreasService.getAllServiceAreas(
        page: currentPage.value,
        limit: limit,
      );

      debugPrint("Service Areas API Response Code: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ServiceAreaResponseModel data;

        if (response.data is Map) {
          data = ServiceAreaResponseModel.fromJson(
            Map<String, dynamic>.from(response.data),
          );
        } else if (response.data is List) {
          data = ServiceAreaResponseModel(
            success: true,
            message: '',
            pagination: PaginationModel(
              total: (response.data as List).length,
              limit: limit,
              page: 1,
              totalPage: 1,
            ),
            data: (response.data as List)
                .map(
                  (e) =>
                      ServiceAreaModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(),
          );
        } else {
          debugPrint("Service Areas API: Unknown data format: ${response.data}");
          return;
        }

        totalPages.value = data.pagination.totalPage;

        if (currentPage.value == 1) {
          serviceAreas.assignAll(data.data);
          if (serviceAreas.isEmpty) {
            debugPrint("Service Areas API: Response successful but data list is empty");
          }
        } else {
          serviceAreas.addAll(data.data);
        }
        debugPrint("Service Areas loaded: ${serviceAreas.length} items (Page ${currentPage.value}/${totalPages.value})");
      } else {
        debugPrint("Service Areas API Error: ${response.statusCode} - ${response.statusMessage}");
      }
    } catch (e) {
      debugPrint("Error fetching service areas: $e");
    } finally {
      isLoading.value = false;
      isMoreLoading.value = false;
    }
  }

  void loadMoreServiceAreas() {
    if (!isLoading.value &&
        !isMoreLoading.value &&
        currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchServiceAreas();
    }
  }

  // Function to toggle the expanded state of a service area
  void toggleExpansion(int index) {
    if (index >= 0 && index < serviceAreas.length) {
      serviceAreas[index].isExpanded = !serviceAreas[index].isExpanded;
      serviceAreas.refresh(); // Notify Rx listeners
    }
  }
}
