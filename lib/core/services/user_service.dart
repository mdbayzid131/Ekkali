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
  final RxString _userEmail = "".obs;
  final RxString _userName = "".obs;
  final RxString _userNickName = "".obs;

  String get userId => _userId.value;
  set userId(String value) => _userId.value = value;

  String get userEmail => _userEmail.value;
  set userEmail(String value) => _userEmail.value = value;

  String get userName => _userName.value;
  set userName(String value) => _userName.value = value;

  String get userNickName => _userNickName.value;
  set userNickName(String value) => _userNickName.value = value;

  @override
  void onInit() {
    super.onInit();
    _userRepo = UserRepo(apiClient: Get.find());
    // Only fetch if token exists to avoid unauthorized API calls
    checkTokenAndFetch();
  }

  /// Check for token and approval before fetching user data
  Future<void> checkTokenAndFetch() async {
    // 1. Try to get user data from storage first
    final String userData = await StorageService.getString(
      StorageConstants.userData,
    );
    if (userData.isNotEmpty) {
      try {
        final Map<String, dynamic> user = json.decode(userData);
        final id = user['_id'] ?? user['id'];
        if (id != null) _userId.value = id.toString();
        final email = user['email']?.toString();
        if (email != null) _userEmail.value = email;
        final name = user['name']?.toString() ?? user['fullName']?.toString();
        if (name != null) _userName.value = name;
        final nickname =
            user['nickName']?.toString() ?? user['nickname']?.toString();
        if (nickname != null) _userNickName.value = nickname;
      } catch (_) {}
    }

    final token = await StorageService.getString(StorageConstants.bearerToken);
    final isApproved = await StorageService.getBool(StorageConstants.isApproved);

    // Fetch latest profile from API if authenticated
    if (token.isNotEmpty && isApproved == true) {
      await fetchUserId();
    }
  }

  /// Fetch user profile and store the ID and user details
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
        final rawData = response.data['data'] ?? response.data;
        if (rawData is Map<String, dynamic>) {
          await StorageService.setString(
            StorageConstants.userData,
            json.encode(rawData),
          );

          final id =
              rawData['_id']?.toString() ?? rawData['id']?.toString();
          if (id != null) {
            _userId.value = id;
            debugPrint("✅ UserService: Set userId from profile API: $id");
          }
          final email = rawData['email']?.toString();
          if (email != null) _userEmail.value = email;
          final name =
              rawData['name']?.toString() ?? rawData['fullName']?.toString();
          if (name != null) _userName.value = name;
          final nickname =
              rawData['nickName']?.toString() ?? rawData['nickname']?.toString();
          if (nickname != null) _userNickName.value = nickname;
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
