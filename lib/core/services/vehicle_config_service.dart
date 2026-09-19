import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/data/models/vehicle_config_model.dart';

class VehicleConfigService extends GetxService {
  ApiClient get _apiClient => Get.find<ApiClient>();

  final RxList<VehicleConfigOption> options = <VehicleConfigOption>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVehicleOptions();
  }

  Future<void> fetchVehicleOptions() async {
    isLoading.value = true;
    try {
      final response = await _apiClient.getData(
        ApiConstants.vehicleConfigOptions,
      );
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'];
        if (rawData is List) {
          final List<VehicleConfigOption> parsed = [];
          for (var item in rawData) {
            if (item is Map<String, dynamic>) {
              parsed.add(VehicleConfigOption.fromJson(item));
            }
          }
          options.assignAll(parsed);
        }
      }
    } catch (e) {
      debugPrint('Error fetching vehicle config options: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper to find vehicle option configuration by vehicle type name (case-insensitive & alias-tolerant)
  VehicleConfigOption? getOptionForType(String? type) {
    if (type == null || type.trim().isEmpty || options.isEmpty) return null;
    final normalized = type.toLowerCase().trim();

    return options.firstWhereOrNull((opt) {
      final optType = opt.vehicleType.toLowerCase().trim();
      if (optType == normalized) return true;

      // Match Sprinter aliases ("Van/Sprinter", "Sprinter", "Van")
      if ((optType.contains('sprinter') || optType.contains('van')) &&
          (normalized.contains('sprinter') || normalized.contains('van'))) {
        return true;
      }

      // Match Limousine aliases ("Stretch Limousine", "LimoStretch", "Limo", "Limo Stretch")
      if ((optType.contains('limo') || optType.contains('stretch')) &&
          (normalized.contains('limo') || normalized.contains('stretch'))) {
        return true;
      }

      return false;
    });
  }

  /// Get allowed colors for a type
  List<String> getAllowedColorsForType(String? type) {
    final option = getOptionForType(type);
    if (option != null && option.allowedColors.isNotEmpty) {
      return option.allowedColors;
    }
    return ['Black'];
  }

  /// Get makes and models for a type
  List<String> getMakesAndModelsForType(String? type) {
    final option = getOptionForType(type);
    if (option != null) {
      return option.makesAndModels;
    }
    return [];
  }

  /// Get max vehicle age for a type
  int getMaxAgeForType(String? type) {
    final option = getOptionForType(type);
    return option?.maxAge ?? 5;
  }
}
