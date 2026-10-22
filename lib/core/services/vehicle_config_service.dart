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
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final parsed = <VehicleConfigOption>[];
      String? nextCursor;
      final seenCursors = <String>{};
      do {
        final response = await _apiClient.getData(
          ApiConstants.vehicleConfigOptions,
          query: nextCursor == null ? null : {'cursor': nextCursor},
        );
        if (response.statusCode == 200 && response.data != null) {
          final rawData = response.data['data'];
          if (rawData is List) {
            for (var item in rawData) {
              if (item is Map<String, dynamic>) {
                parsed.add(VehicleConfigOption.fromJson(item));
              }
            }
          }
          final cursor = response.data['cursor'];
          nextCursor = cursor is Map && cursor['hasMore'] == true
              ? cursor['nextCursor']?.toString()
              : null;
        } else {
          return;
        }
      } while (nextCursor != null &&
          nextCursor.isNotEmpty &&
          seenCursors.add(nextCursor));
      options.assignAll(parsed);
    } catch (e) {
      debugPrint('Error fetching vehicle config options: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get vehicleTypes {
    final seen = <String>{};
    return options
        .map((option) => option.vehicleType.trim())
        .where((type) => type.isNotEmpty && seen.add(type.toLowerCase()))
        .toList();
  }

  static String _typeKey(String type) {
    final key = type.trim().toLowerCase();
    if (const ['van/sprinter', 'sprinter', 'van'].contains(key)) {
      return 'sprinter';
    }
    if (const [
      'stretch limousine',
      'limo stretch',
      'limostretch',
      'limo',
    ].contains(key)) {
      return 'limo';
    }
    return key;
  }

  bool matchesType(String a, String b) => _typeKey(a) == _typeKey(b);

  /// Helper to find vehicle option configuration by vehicle type name (case-insensitive & alias-tolerant)
  VehicleConfigOption? getOptionForType(String? type) {
    if (type == null || type.trim().isEmpty || options.isEmpty) return null;
    return options.firstWhereOrNull(
          (opt) =>
              opt.vehicleType.trim().toLowerCase() == type.trim().toLowerCase(),
        ) ??
        options.firstWhereOrNull((opt) => matchesType(opt.vehicleType, type));
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
