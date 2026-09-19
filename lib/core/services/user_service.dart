import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/services/user_profile_service.dart';
import 'package:moeb_26/data/repositories/user_repository.dart';

class UserService extends GetxService {
  late UserRepo _userRepo;
  final RxString _userId = "".obs;

  String get userId => _userId.value;
  set userId(String value) => _userId.value = value;

  @override
  void onInit() {
    super.onInit();
    _userRepo = UserRepo(apiClient: Get.find());
    // Only fetch if token exists to avoid unauthorized API calls
    checkTokenAndFetch();
  }

  /// Check for token and approval before fetching user data
  Future<void> checkTokenAndFetch() async {
    // 1. Try to get userId from storage first
    final String userData = await StorageService.getString(
      StorageConstants.userData,
    );
    if (userData.isNotEmpty) {
      try {
        final Map<String, dynamic> user = json.decode(userData);
        final id = user['_id'] ?? user['id'];
        if (id != null) {
          _userId.value = id.toString();
          return;
        }
      } catch (_) {}
    }

    final token = await StorageService.getString(StorageConstants.bearerToken);
    final isApproved = await StorageService.getBool(StorageConstants.isApproved);

    // Only call API if user is approved and token exists
    if (token.isNotEmpty && isApproved == true) {
      await fetchUserId();
    }
  }

  /// Fetch user profile and store the ID if not already set
  Future<void> fetchUserId() async {
    try {
      final token = await StorageService.getString(
        StorageConstants.bearerToken,
      );
      final isApproved = await StorageService.getBool(StorageConstants.isApproved);
      if (token.isEmpty || isApproved != true) return;

      final profileService = Get.find<UserProfileService>();
      final response = await profileService.getUserProfile();
      if (response.statusCode == 200 && response.data != null) {
        final id =
            response.data['data']?['_id']?.toString() ??
            response.data['data']?['id']?.toString();
        if (id != null) {
          _userId.value = id;
          debugPrint("✅ UserService: Set userId from profile API: $id");
        }
      }
    } catch (e) {
      debugPrint("❌ UserService: Error fetching userId: $e");
    }
  }

  Future<UserService> init() async {
    return this;
  }

  // ========== Vehicle only ==========
  Future<Response> updateVehicles({
    required List<Map<String, dynamic>> vehicles,
  }) async {
    try {
      return await _userRepo.updateVehicles(vehicles: vehicles);
    } catch (e) {
      rethrow;
    }
  }

  // ========== Documents only ==========
  Future<Response> updateDocuments({
    required List<Map<String, dynamic>> vehicles, // 👈 যোগ করা হয়েছে
    required File drivingLicense,
    required String drivingLicenseExpire,
    required File hackLicense,
    required String hackLicenseExpire,
    File? localPermit,
    String? localPermitExpire,
    required File commercialInsurance,
    required String commercialInsuranceExpire,
    required File vehicleRegistration,
    required String vehicleRegistrationExpire,
    required File headshot,
    required File frontView,
    required File rearView,
    required File interiorView,
  }) async {
    try {
      return await _userRepo.updateDocuments(
        vehicles: vehicles, // 👈 pass করো
        drivingLicense: drivingLicense,
        drivingLicenseExpire: drivingLicenseExpire,
        hackLicense: hackLicense,
        hackLicenseExpire: hackLicenseExpire,
        localPermit: localPermit,
        localPermitExpire: localPermitExpire,
        commercialInsurance: commercialInsurance,
        commercialInsuranceExpire: commercialInsuranceExpire,
        vehicleRegistration: vehicleRegistration,
        vehicleRegistrationExpire: vehicleRegistrationExpire,
        headshot: headshot,
        frontView: frontView,
        rearView: rearView,
        interiorView: interiorView,
      );
    } catch (e) {
      rethrow;
    }
  }
}
