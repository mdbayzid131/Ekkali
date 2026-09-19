import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/services/job_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/favorite_chauffeur_model.dart';
import 'package:moeb_26/data/models/service_area_model.dart';
import 'package:moeb_26/data/repositories/favorite_chauffeur_repository.dart';
import 'package:moeb_26/data/repositories/serviceAreas_repository.dart';

class PostJobController extends GetxController {
  final JobService _jobService = Get.find<JobService>();
  late final FavoriteChauffeurRepo _favoriteRepo;
  late final ServiceAreasRepo _serviceAreasRepo;

  // Job Type & Vehicle
  var jobType = 'One Way'.obs;
  var selectedVehicle = ''.obs;
  var isLoading = false.obs;

  // Chauffeur Selection State
  var chauffeurSelectionType = ''.obs; // '', 'global', or 'favorites'
  var selectedDrivers = <String>[].obs;
  var selectedServiceAreas = <String>[].obs;

  final RxList<FavoriteChauffeurModel> favoriteDrivers =
      <FavoriteChauffeurModel>[].obs;
  final RxBool isFavoriteDriversLoading = false.obs;

  final RxList<ServiceAreaModel> serviceAreas = <ServiceAreaModel>[].obs;
  final RxBool isServiceAreasLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _favoriteRepo = Get.isRegistered<FavoriteChauffeurRepo>()
        ? Get.find<FavoriteChauffeurRepo>()
        : Get.put(FavoriteChauffeurRepo(apiClient: Get.find<ApiClient>()));

    _serviceAreasRepo = Get.isRegistered<ServiceAreasRepo>()
        ? Get.find<ServiceAreasRepo>()
        : Get.put(ServiceAreasRepo(apiClient: Get.find<ApiClient>()));

    fetchFavoriteDrivers();
    fetchServiceAreas();
  }

  Future<void> fetchFavoriteDrivers() async {
    isFavoriteDriversLoading.value = true;
    try {
      final response = await _favoriteRepo.getFavorites(limit: 50);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> dataList = response.data?['data'] ?? [];
        final items = dataList
            .map((e) => FavoriteChauffeurModel.fromJson(e))
            .toList();
        favoriteDrivers.assignAll(items);
      }
    } catch (e) {
      debugPrint("Error fetching favorite chauffeurs for job post: $e");
    } finally {
      isFavoriteDriversLoading.value = false;
    }
  }

  Future<void> fetchServiceAreas() async {
    isServiceAreasLoading.value = true;
    try {
      final response = await _serviceAreasRepo.getAllServiceAreas(
        page: 1,
        limit: 50,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> dataList = response.data is Map
            ? (response.data['data'] ?? response.data['service_areas'] ?? [])
            : (response.data is List ? response.data : []);
        final items = dataList
            .map((e) => ServiceAreaModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        serviceAreas.assignAll(items);
      }
    } catch (e) {
      debugPrint("Error fetching service areas for job post: $e");
    } finally {
      isServiceAreasLoading.value = false;
    }
  }

  String get chauffeurSelectionText {
    if (chauffeurSelectionType.value == 'global') {
      if (selectedServiceAreas.isEmpty) {
        return 'Auto-assign: All Chauffeurs';
      }
      final cities = selectedServiceAreas
          .map((city) => city.split(',').first.trim())
          .join(', ');
      return 'Auto-assign: $cities';
    } else if (chauffeurSelectionType.value == 'favorites' &&
        selectedDrivers.isNotEmpty) {
      final names = favoriteDrivers
          .where((d) => selectedDrivers.contains(d.id))
          .map((d) => d.name)
          .join(', ');
      return names.isNotEmpty ? 'Preferred: $names' : 'Preferred Chauffeur';
    }
    return 'Select Chauffeur / Service Area';
  }

  void selectGlobal() {
    chauffeurSelectionType.value = 'global';
    selectedDrivers.clear();
  }

  void toggleDriverSelection(String driverId) {
    if (chauffeurSelectionType.value != 'favorites') {
      chauffeurSelectionType.value = 'favorites';
      selectedDrivers.clear();
      selectedServiceAreas.clear();
    }
    if (selectedDrivers.contains(driverId)) {
      selectedDrivers.remove(driverId);
      if (selectedDrivers.isEmpty) {
        chauffeurSelectionType.value = '';
      }
    } else {
      selectedDrivers.add(driverId);
    }
  }

  void toggleServiceAreaSelection(String area) {
    if (chauffeurSelectionType.value != 'global') {
      chauffeurSelectionType.value = 'global';
      selectedDrivers.clear();
      selectedServiceAreas.clear();
    }
    if (selectedServiceAreas.contains(area)) {
      selectedServiceAreas.remove(area);
      if (selectedServiceAreas.isEmpty) {
        chauffeurSelectionType.value = '';
      }
    } else {
      selectedServiceAreas.add(area);
    }
  }

  var expandedCitiesAreas = <String>{}.obs;

  void toggleShowAllCities(String areaName) {
    if (expandedCitiesAreas.contains(areaName)) {
      expandedCitiesAreas.remove(areaName);
    } else {
      expandedCitiesAreas.add(areaName);
    }
  }

  void clearServiceAreaSelection() {
    selectedServiceAreas.clear();
    if (chauffeurSelectionType.value == 'global') {
      chauffeurSelectionType.value = '';
    }
  }

  // Shared Date, Time, and Payment State
  var selectedRole = 'Credit Card on File'.obs;
  var roles = ['Credit Card on File', 'Collect Payment'].obs;

  var selectedDate = Rxn<DateTime>();
  var selectedTime = Rxn<TimeOfDay>();
  var formattedTime = "".obs;
  var isAsap = false.obs;
  var showAsapError = false.obs;

  void changeJobType(String newType) {
    jobType.value = newType;
  }

  void selectVehicle(String vehicle) {
    selectedVehicle.value = vehicle;
  }

  void toggleAsap(bool? value) {
    isAsap.value = value ?? false;
    showAsapError.value = false;
  }

  void pickRole(String role) {
    selectedRole.value = role;
  }

  // Date and Time Pickers
  Future<void> chooseDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF364153), // Selected date circle color
              onPrimary: Colors.white, // Selected date text color
              surface: Color(0xFF1E1E1E), // Slightly lighter than pure black
              onSurface: Colors.white, // Text color on the picker
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF404040), width: 1),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
    }
  }

  Future<void> chooseTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF364153), // Selection hand and selected circle
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E), // Lighter background
              onSurface: Colors.white, // Text color
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF404040), width: 1),
              ),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != selectedTime.value) {
      selectedTime.value = picked;

      // Format to 12-hour AM/PM for display
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      formattedTime.value = DateFormat('hh:mm a').format(dateTime);
    }
  }

  // ========== One Way Job Submit ==========
  Future<void> submitOneWayJob({
    required String pickupLocation,
    required String dropoffLocation,
    required String flightNumber,
    DateTime? date,
    TimeOfDay? time,
    bool? asap,
    required String paymentAmount,
    required String paymentType,
    required String? instruction,
  }) async {
    try {
      isLoading.value = true;

      final isAsapRide = asap == true;
      final String? formattedDate = !isAsapRide && date != null
          ? "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
          : null;
      final String? formattedTimeStr = !isAsapRide && time != null
          ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}"
          : null;

      final String normalizedPayment =
          (paymentType.toUpperCase().contains("COLLECT") &&
              !paymentType.toUpperCase().contains("CREDIT"))
          ? "COLLECT PAYMENT"
          : "CREDIT CARD ON FILE";

      final bool isTargeted =
          chauffeurSelectionType.value == 'favorites' &&
          selectedDrivers.isNotEmpty;
      final String dispatchType = isTargeted
          ? "TARGETED CHAUFFEURS"
          : "ALL CHAUFFEURS";
      final List<String> targetedChauffeurs = isTargeted
          ? selectedDrivers.toList()
          : [];

      List<String> serviceAreaIds = [];
      if (!isTargeted && selectedServiceAreas.isNotEmpty) {
        for (final areaName in selectedServiceAreas) {
          final areaModel = serviceAreas.firstWhereOrNull(
            (a) =>
                a.areaName.trim().toLowerCase() ==
                areaName.trim().toLowerCase(),
          );
          if (areaModel != null && areaModel.id.isNotEmpty) {
            serviceAreaIds.add(areaModel.id);
          }
        }
      }

      final response = await _jobService.createJob(
        jobType: "ONE WAY",
        pickup: pickupLocation,
        dropoff: dropoffLocation,
        flightNumber: flightNumber.isNotEmpty ? flightNumber : null,
        date: formattedDate,
        time: formattedTimeStr,
        asap: isAsapRide,
        vehicleType: selectedVehicle.value,
        paymentAmount: double.tryParse(paymentAmount) ?? 0,
        paymentType: normalizedPayment,
        dispatchType: dispatchType,
        instruction: instruction?.isNotEmpty == true ? instruction : null,
        targetedChauffeurs: targetedChauffeurs,
        serviceAreaId: serviceAreaIds.isNotEmpty ? serviceAreaIds.first : null,
        serviceAreaIds: serviceAreaIds.isNotEmpty ? serviceAreaIds : null,
      );

      final int code = response.statusCode ?? 0;
      final bool isSuccess =
          (code >= 200 && code < 300) || response.data?['success'] == true;

      if (isSuccess) {
        Get.back(); // Pop JobPostSheetTabBarView back to JobOfferView
        Helpers.showCustomSnackBar(
          response.data?['message']?.toString() ?? 'Job created successfully!',
          isError: false,
        );
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Something went wrong.')
            : 'Something went wrong.';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Something went wrong.';
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ========== By The Hour Job Submit ==========
  Future<void> submitByTheHourJob({
    required String pickupLocation,
    String? dropoffLocation,
    String? duration,
    DateTime? date,
    TimeOfDay? time,
    bool? asap,
    required String paymentAmount,
    required String paymentType,
    required String? instruction,
  }) async {
    try {
      isLoading.value = true;

      final isAsapRide = asap == true;
      final String? formattedDate = !isAsapRide && date != null
          ? "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
          : null;
      final String? formattedTimeStr = !isAsapRide && time != null
          ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}"
          : null;

      final String normalizedPayment =
          (paymentType.toUpperCase().contains("COLLECT") &&
              !paymentType.toUpperCase().contains("CREDIT"))
          ? "COLLECT PAYMENT"
          : "CREDIT CARD ON FILE";

      final bool isTargeted =
          chauffeurSelectionType.value == 'favorites' &&
          selectedDrivers.isNotEmpty;
      final String dispatchType = isTargeted
          ? "TARGETED CHAUFFEURS"
          : "ALL CHAUFFEURS";
      final List<String> targetedChauffeurs = isTargeted
          ? selectedDrivers.toList()
          : [];

      List<String> serviceAreaIds = [];
      if (!isTargeted && selectedServiceAreas.isNotEmpty) {
        for (final areaName in selectedServiceAreas) {
          final areaModel = serviceAreas.firstWhereOrNull(
            (a) =>
                a.areaName.trim().toLowerCase() ==
                areaName.trim().toLowerCase(),
          );
          if (areaModel != null && areaModel.id.isNotEmpty) {
            serviceAreaIds.add(areaModel.id);
          }
        }
      }

      final String finalDropoff =
          (dropoffLocation != null && dropoffLocation.isNotEmpty)
          ? dropoffLocation
          : "By the hour";

      final response = await _jobService.createJob(
        jobType: "BY THE HOUR",
        pickup: pickupLocation,
        dropoff: finalDropoff,
        date: formattedDate,
        time: formattedTimeStr,
        asap: isAsapRide,
        vehicleType: selectedVehicle.value,
        paymentAmount: double.tryParse(paymentAmount) ?? 0,
        paymentType: normalizedPayment,
        dispatchType: dispatchType,
        instruction: instruction?.isNotEmpty == true ? instruction : null,
        targetedChauffeurs: targetedChauffeurs,
        serviceAreaId: serviceAreaIds.isNotEmpty ? serviceAreaIds.first : null,
        serviceAreaIds: serviceAreaIds.isNotEmpty ? serviceAreaIds : null,
      );

      final int code = response.statusCode ?? 0;
      final bool isSuccess =
          (code >= 200 && code < 300) || response.data?['success'] == true;

      if (isSuccess) {
        Get.back(); // Pop JobPostSheetTabBarView back to JobOfferView
        Helpers.showCustomSnackBar(
          response.data?['message']?.toString() ?? 'Job created successfully!',
          isError: false,
        );
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Something went wrong.')
            : 'Something went wrong.';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Something went wrong.';
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
