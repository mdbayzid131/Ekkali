import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/config/constants/app_constants.dart';
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/services/firebase_notification_service.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/services/subscription_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/data/repositories/auth_reporitory.dart';
import 'package:moeb_26/data/models/vehicle_model.dart';

class AuthService extends GetxService {
  late AuthRepo _authRepo;

  final isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authRepo = AuthRepo(apiClient: Get.find<ApiClient>());
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await StorageService.getString(StorageConstants.bearerToken);
    isLoggedIn.value = token.isNotEmpty;
  }

  Future<AuthService> init() async => this;

  /// ===================== SIGNUP =====================
  Future<Response> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String serviceAreaId,
    required String companyName,
    required String companyRole,
  }) async {
    return await _authRepo.signup(
      name: name,
      email: email,
      password: password,
      phone: phone,
      serviceAreaId: serviceAreaId,
      companyName: companyName,
      companyRole: companyRole,
    );
  }

  /// ===================== VEHICLE SETUP =====================
  Future<Response> addVehicle({
    required List<VehicleModel> vehicles,
  }) async {
    return await _authRepo.addVehicle(vehicles: vehicles);
  }

  /// ===================== DOCUMENTS UPLOAD =====================
  Future<Response> uploadDocuments({
    required File drivingLicenseFile,
    required String drivingLicenseExpiry,
    required File hackLicenseFile,
    required String hackLicenseExpiry,
    File? localPermitFile,
    String? localPermitExpiry,
    required File headshotFile,
  }) async {
    return await _authRepo.uploadDocuments(
      drivingLicenseFile: drivingLicenseFile,
      drivingLicenseExpiry: drivingLicenseExpiry,
      hackLicenseFile: hackLicenseFile,
      hackLicenseExpiry: hackLicenseExpiry,
      localPermitFile: localPermitFile,
      localPermitExpiry: localPermitExpiry,
      headshotFile: headshotFile,
    );
  }

  /// ===================== LOGIN =====================
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("Error fetching FCM token: $e");
      }

      AppConstants.fcmToken = fcmToken ?? AppConstants.fcmToken;
      await StorageService.setString(
        StorageConstants.fcmToken,
        AppConstants.fcmToken,
      );

      final response = await _authRepo.login(
        email: email,
        password: password,
        deviceToken: AppConstants.fcmToken,
      );

      await handleAuthResponse(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// ===================== LOGOUT =====================
  Future<Response> logout() async {
    try {
      try {
        await FirebaseNotificationService.removeTokenFromBackend();
      } catch (e) {
        debugPrint("Error removing device token on logout: $e");
      }

      final response = await _authRepo.logout(
        deviceToken: AppConstants.fcmToken,
      );
      await clearLocalAuth();
      Get.offAllNamed(Routes.signinView);
      return response;
    } catch (e) {
      await clearLocalAuth();
      Get.offAllNamed(Routes.signinView);
      rethrow;
    }
  }

  /// ===================== FORGOT PASSWORD =====================
  Future<Response> forgotPassword(String email) async {
    return await _authRepo.forgotPassword(email: email);
  }

  /// ===================== OTP VERIFY =====================
  Future<Response> verifyOtp({
    required String email,
    required int otp,
  }) async {
    final response = await _authRepo.otpVerify(
      email: email,
      oneTimeCode: otp,
    );
    await handleAuthResponse(response);
    return response;
  }

  /// ===================== RESEND OTP =====================
  Future<Response> resendOtp(String email) async {
    return await _authRepo.resentOtp(email: email);
  }

  /// ===================== RESET PASSWORD =====================
  Future<Response> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await _authRepo.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  /// ===================== CHANGE PASSWORD =====================
  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await _authRepo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  /// ===================== HANDLE AUTH RESPONSE =====================
  Future<void> handleAuthResponse(Response response) async {
    try {
      final authData = response.data?['data'] ?? response.data;
      if (authData is! Map<String, dynamic>) return;

      final String? accessToken = authData['accessToken'] ?? authData['token'];
      final bool isApproved = authData['isApproved'] == true;
      final bool isOnboard = authData['isOnboard'] == true;

      // 1. Save Token
      if (accessToken != null && accessToken.isNotEmpty) {
        await StorageService.setString(
          StorageConstants.bearerToken,
          accessToken,
        );
        isLoggedIn.value = true;

        try {
          Get.find<SocketService>().initSocket();
        } catch (_) {}

        try {
          await FirebaseNotificationService.sendTokenToBackend(
            AppConstants.fcmToken,
          );
        } catch (_) {}
      }

      // 2. Save Status Flags
      await StorageService.setBool(StorageConstants.isApproved, isApproved);
      await StorageService.setBool(StorageConstants.isOnboard, isOnboard);
      await StorageService.setBool(
        StorageConstants.isOnboardingCompleted,
        isOnboard,
      );

      // 3. User info if present
      final user = authData['user'] ?? authData;
      if (user is Map<String, dynamic>) {
        final id = user['_id'] ?? user['id'];
        if (id != null) {
          final userService = Get.find<UserService>();
          userService.userId = id.toString();
          userService.fetchUserId();
        }
      }

      // 4. Sync subscription status for the newly logged-in user (only if approved and onboarded)
      try {
        if (isApproved && isOnboard) {
          if (Get.isRegistered<SubscriptionService>()) {
            Get.find<SubscriptionService>().syncStatusWithBackend();
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint("Error handling auth response: $e");
    }
  }

  /// ===================== CLEAR LOCAL AUTH =====================
  Future<void> clearLocalAuth() async {
    await StorageService.remove(StorageConstants.bearerToken);
    await StorageService.remove(StorageConstants.refreshToken);
    await StorageService.remove(StorageConstants.userData);
    await StorageService.remove(StorageConstants.isApproved);
    await StorageService.remove(StorageConstants.isOnboard);
    await StorageService.remove(StorageConstants.isOnboardingCompleted);

    // Clear subscription local data on logout
    try {
      if (Get.isRegistered<SubscriptionService>()) {
        await Get.find<SubscriptionService>().clearSubscriptionData();
      } else {
        await StorageService.remove(StorageConstants.isPremium);
        await StorageService.remove(StorageConstants.subscriptionExpiry);
      }
    } catch (_) {}

    ApiClient.temporaryToken = null;
    isLoggedIn.value = false;
  }

  bool get isAuthenticated => isLoggedIn.value;
}
