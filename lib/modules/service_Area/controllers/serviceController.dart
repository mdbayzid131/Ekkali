import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/core/services/serviceAreas_service.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/services/user_profile_service.dart';
import 'package:moeb_26/data/models/service_area_model.dart';

class ServiceAreaController extends GetxController {
  final ServiceAreaService _serviceAreasService = Get.put(ServiceAreaService());

  RxList<ServiceAreaModel> serviceAreas = <ServiceAreaModel>[].obs;
  var isLoading = false.obs;
  var isMoreLoading = false.obs;
  var nextCursor = RxnString();
  var hasMore = false.obs;

  final ScrollController scrollController = ScrollController();

  // Selected service area names list for multi-selection
  var selectedAreaNames = <String>[].obs;
  var expandedCitiesAreas = <String>{}.obs;

  void toggleShowAllCities(String areaName) {
    if (expandedCitiesAreas.contains(areaName)) {
      expandedCitiesAreas.remove(areaName);
    } else {
      expandedCitiesAreas.add(areaName);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initCurrentServiceArea();
    fetchServiceAreas();
    scrollController.addListener(_onScroll);
  }

  Future<void> _initCurrentServiceArea() async {
    try {
      final token = await StorageService.getString(StorageConstants.bearerToken);
      if (token.isEmpty) return;

      final isApproved = await StorageService.getBool(StorageConstants.isApproved);
      if (isApproved != true) return;

      if (Get.isRegistered<UserProfileService>()) {
        final profileService = Get.find<UserProfileService>();
        profileService.getUserProfile().then((response) {
          if (response.statusCode == 200 &&
              response.data != null &&
              response.data['data'] != null) {
            final rawArea = response.data['data']['serviceArea'] ??
                response.data['data']['serviceAreas'];
            if (rawArea is List) {
              selectedAreaNames.assignAll(
                rawArea.map((e) => e.toString()).toList(),
              );
            } else if (rawArea is String && rawArea.isNotEmpty) {
              selectedAreaNames.assignAll([rawArea]);
            }
          }
        }).catchError((e) {
          debugPrint("Error initializing current service area: $e");
        });
      }
    } catch (e) {
      debugPrint("UserProfileService not available: $e");
    }
  }

  void selectServiceArea(String areaName) {
    toggleServiceArea(areaName);
  }

  void toggleServiceArea(String areaName) {
    if (selectedAreaNames.contains(areaName)) {
      selectedAreaNames.remove(areaName);
    } else {
      selectedAreaNames.add(areaName);
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
        hasMore.value &&
        nextCursor.value != null) {
      loadMoreServiceAreas();
    }
    return Future.value();
  }

  Future<void> fetchServiceAreas({bool isRefresh = false}) async {
    if (isLoading.value || isMoreLoading.value) return;

    if (isRefresh) {
      nextCursor.value = null;
    }

    try {
      if (nextCursor.value == null) {
        isLoading.value = true;
      } else {
        isMoreLoading.value = true;
      }

      final response = await _serviceAreasService.getAllServiceAreas(
        limit: 50,
        cursor: isRefresh ? null : nextCursor.value,
      );

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
            data: (response.data as List)
                .map(
                  (e) => ServiceAreaModel.fromJson(
                    e is Map ? Map<String, dynamic>.from(e) : {'areaName': e.toString()},
                  ),
                )
                .toList(),
          );
        } else {
          debugPrint("Service Areas API: Unknown data format: ${response.data}");
          return;
        }

        hasMore.value = data.cursor?.hasMore ?? false;
        final newCursor = data.cursor?.nextCursor;

        if (isRefresh || nextCursor.value == null) {
          serviceAreas.assignAll(data.data);
        } else {
          serviceAreas.addAll(data.data);
        }
        nextCursor.value = newCursor;
        debugPrint("Service Areas loaded: ${serviceAreas.length} items");
      } else {
        debugPrint("Service Areas API Error: ${response.statusCode}");
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
        hasMore.value &&
        nextCursor.value != null) {
      fetchServiceAreas();
    }
  }

  void toggleExpansion(int index) {
    if (index >= 0 && index < serviceAreas.length) {
      serviceAreas[index].isExpanded = !serviceAreas[index].isExpanded;
      serviceAreas.refresh();
    }
  }
}
