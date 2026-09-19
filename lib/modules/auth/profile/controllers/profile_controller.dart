import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/services/user_profile_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/utils/media_picker_helper.dart';
import '../../../../data/models/user_profile_model.dart';

class ProfileController extends GetxController {
  final UserProfileService _profileService = Get.find<UserProfileService>();

  // Profile data
  var fullName = "".obs;
  var email = "".obs;
  var phone = "".obs;
  var serviceArea = "".obs;
  var nickName = "".obs;
  var rating = 5.0.obs;
  var ecn = "".obs;
  var profilePicture = "".obs;
  var pickedImage = Rxn<File>();

  // Extended Driver / Chauffeur Profile Fields
  var company = "Executive Chauffeur Services".obs;
  var carTag = "Luxury SUV & Sedan".obs;
  var zelle = "pay@chauffeur.com".obs;
  var venmo = "@ChauffeurPay".obs;
  var cashApp = "\$ChauffeurApp".obs;
  var cardPaymentAccepted = true.obs;

  var isLoading = false.obs;
  var isUpdating = false.obs;
  var userProfile = Rxn<UserProfileModel>();

  // Vehicles Fleet List (GET /api/v1/vehicles)
  var vehiclesList = <Vehicle>[].obs;
  var isVehiclesLoading = false.obs;

  // Service Areas
  var serviceAreas = <String>[].obs;
  var isServiceAreasLoading = false.obs;

  // Legal Pages
  var legalPages = <Map<String, dynamic>>[].obs;
  var isLegalsLoading = false.obs;

  // Controllers for Edit Profile Form
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController serviceAreaController;
  late TextEditingController nickNameController;

  // Extended Chauffeur Controllers
  late TextEditingController companyController;
  late TextEditingController carTagController;
  late TextEditingController zelleController;
  late TextEditingController venmoController;
  late TextEditingController cashAppController;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    serviceAreaController = TextEditingController();
    nickNameController = TextEditingController();

    companyController = TextEditingController(text: company.value);
    carTagController = TextEditingController(text: carTag.value);
    zelleController = TextEditingController(text: zelle.value);
    venmoController = TextEditingController(text: venmo.value);
    cashAppController = TextEditingController(text: cashApp.value);

    fetchUserProfile();
    fetchVehicles();
    fetchServiceAreas();
    fetchLegalPages();
  }

  /// Fetches vehicles list from GET /api/v1/vehicles
  Future<void> fetchVehicles() async {
    isVehiclesLoading.value = true;
    try {
      var response = await _profileService.getVehicles();
      if (response.statusCode == 200 || response.statusCode == 201) {
        var rawData = response.data['data'];
        if (rawData is List) {
          vehiclesList.value =
              rawData.map((e) => Vehicle.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching vehicles: $e");
    } finally {
      isVehiclesLoading.value = false;
    }
  }

  /// Deletes a vehicle from DELETE /api/v1/vehicles/:vehicleId
  Future<void> deleteVehicle(String vehicleId) async {
    isUpdating.value = true;
    try {
      var response = await _profileService.deleteVehicle(vehicleId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        vehiclesList.removeWhere((v) => v.id == vehicleId);
        Get.back(); // Close confirmation dialog
        Helpers.showCustomSnackBar(
          "Vehicle deleted successfully",
          isError: false,
        );
      } else {
        Get.back();
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? "Failed to delete vehicle",
          isError: true,
        );
      }
    } catch (e) {
      Get.back();
      debugPrint("Error deleting vehicle: $e");
      Helpers.showCustomSnackBar(
        "Failed to delete vehicle",
        isError: true,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Refresh all profile-related data (User profile, Vehicles, Service areas, Legal pages)
  Future<void> refreshProfile() async {
    await Future.wait([
      fetchUserProfile(),
      fetchVehicles(),
      fetchServiceAreas(),
      fetchLegalPages(),
    ]);
  }

  Future<void> fetchLegalPages() async {
    isLegalsLoading.value = true;
    try {
      var response = await _profileService.getLegals();
      if (response.statusCode == 200 && response.data != null) {
        var rawData = response.data['data'];
        if (rawData is List) {
          legalPages.value = rawData
              .map(
                (item) {
                  final title = item['title']?.toString() ?? '';
                  final slug = (item['slug'] != null &&
                          item['slug'].toString().isNotEmpty)
                      ? item['slug'].toString()
                      : (item['_id']?.toString() ??
                          title.toLowerCase().replaceAll(' ', '-'));
                  return {
                    'id': item['_id']?.toString() ?? '',
                    'slug': slug,
                    'title': title,
                  };
                },
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching legal pages: $e");
    } finally {
      isLegalsLoading.value = false;
    }
  }

  Future<void> fetchServiceAreas() async {
    isServiceAreasLoading.value = true;
    try {
      var response = await _profileService.getServiceAreas();
      if (response.statusCode == 200) {
        var dataList = response.data['data'] as List;
        serviceAreas.value = dataList
            .map((item) => item['areaName'].toString())
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching service areas: $e");
    } finally {
      isServiceAreasLoading.value = false;
    }
  }

  Future<void> fetchUserProfile() async {
    isLoading.value = true;
    try {
      var response = await _profileService.getUserProfile();
      if (response.statusCode == 200 && response.data?['data'] != null) {
        _applyProfileData(response.data['data']);
      } else {
        Helpers.showCustomSnackBar("Failed to load profile", isError: true);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _applyProfileData(Map<String, dynamic> data) {
    userProfile.value = UserProfileModel.fromJson(data);

    fullName.value = data['name']?.toString() ?? "";
    email.value = data['email']?.toString() ?? "";
    phone.value = data['phone']?.toString() ?? "";
    serviceArea.value = data['serviceArea']?.toString() ?? "";
    nickName.value = data['nickname']?.toString() ?? "";
    profilePicture.value = data['profilePicture']?.toString() ??
        data['uploadedHeadshot']?.toString() ??
        "";
    rating.value = (data['averageRating'] is num)
        ? (data['averageRating'] as num).toDouble()
        : 5.0;
    ecn.value = data['uid']?.toString() ?? "";

    company.value = data['companyName']?.toString() ??
        data['company']?.toString() ??
        "";



    final pm = data['paymentMethods'];
    if (pm is Map) {
      zelle.value = pm['zelle'] is Map
          ? (pm['zelle']['email']?.toString() ?? '')
          : '';
      venmo.value = pm['venmo'] is Map
          ? (pm['venmo']['username']?.toString() ?? '')
          : '';
      cashApp.value = pm['cashApp'] is Map
          ? (pm['cashApp']['cashtag']?.toString() ?? '')
          : '';
      cardPaymentAccepted.value =
          pm['cardPayment'] is Map && pm['cardPayment']['status'] == 'ACCEPTED';
    }

    // Sync Text Editing Controllers
    nameController.text = fullName.value;
    emailController.text = email.value;
    phoneController.text = phone.value;
    serviceAreaController.text = serviceArea.value;
    nickNameController.text = nickName.value;
    companyController.text = company.value;
    zelleController.text = zelle.value;
    venmoController.text = venmo.value;
    cashAppController.text = cashApp.value;
  }

  Future<void> pickImage(BuildContext context) async {
    final hasUploadedPhoto =
        userProfile.value?.profilePicture != null &&
        userProfile.value!.profilePicture.isNotEmpty;
    if (hasUploadedPhoto) {
      Helpers.showCustomSnackBar(
        "Profile pictures cannot be changed once uploaded.",
        isError: true,
      );
      return;
    }
    final File? image = await MediaPickerHelper.pickSingleImage(context);

    if (image != null) {
      final compressed = await Helpers.compressImage(image);
      pickedImage.value = compressed;
    }
  }

  Future<void> updateSelectedVehicle(String vehicleId) async {
    isUpdating.value = true;
    try {
      var response = await _profileService.selectVehicle(vehicleId);
      if (response.statusCode == 200) {
        var data = response.data['data'];
        String? newSelectedVehicleId;
        if (data != null && data is Map && data['selectedVehicle'] != null) {
          newSelectedVehicleId = data['selectedVehicle']['_id']?.toString() ??
              data['selectedVehicle']['id']?.toString() ??
              data['selectedVehicle'].toString();
        } else {
          newSelectedVehicleId = vehicleId;
        }

        if (userProfile.value != null) {
          userProfile.value = UserProfileModel(
            id: userProfile.value!.id,
            name: userProfile.value!.name,
            role: userProfile.value!.role,
            email: userProfile.value!.email,
            phone: userProfile.value!.phone,
            home: userProfile.value!.home,
            serviceArea: userProfile.value!.serviceArea,
            experience: userProfile.value!.experience,
            company: userProfile.value!.company,
            companyRole: userProfile.value!.companyRole,
            profilePicture: userProfile.value!.profilePicture,
            status: userProfile.value!.status,
            verified: userProfile.value!.verified,
            deviceTokens: userProfile.value!.deviceTokens,
            vehicles: userProfile.value!.vehicles,
            createdAt: userProfile.value!.createdAt,
            updatedAt: DateTime.now(),
            averageRating: userProfile.value!.averageRating,
            selectedVehicle: newSelectedVehicleId,
            nickname: userProfile.value!.nickname,
            uid: userProfile.value!.uid,
          );
        } else {
          fetchUserProfile();
        }

        Helpers.showCustomSnackBar(
          response.data['message'] ?? "Vehicle selected successfully",
          isError: false,
        );
      } else {
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? "Failed to select vehicle",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Error selecting vehicle: $e");
      Helpers.showCustomSnackBar(
        "Something went wrong while selecting vehicle",
        isError: true,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> savePaymentDetails() async {
    isUpdating.value = true;
    try {
      Map<String, dynamic> body = {
        "paymentMethods": {
          "zelle": {
            "email": zelleController.text.trim(),
          },
          "venmo": {
            "username": venmoController.text.trim(),
          },
          "cashApp": {
            "cashtag": cashAppController.text.trim(),
          },
          "cardPayment": {
            "status": cardPaymentAccepted.value ? "ACCEPTED" : "NOT_ACCEPTED",
          }
        }
      };

      var response = await _profileService.patchProfile(body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data?['success'] != false &&
          response.data?['data'] != null) {
        _applyProfileData(response.data['data']);
        Get.back();
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? "Payment details updated successfully",
          isError: false,
        );
      } else {
        final errorMsg =
            response.data?['message'] ?? "Failed to update payment details";
        Helpers.showCustomSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      debugPrint("Error updating payment details: $e");
      String errorMsg = "Failed to update payment details";
      if (e is dio.DioException && e.response?.data != null) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      Helpers.showCustomSnackBar(errorMsg, isError: true);
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> saveProfile() async {
    isUpdating.value = true;
    try {
      Map<String, dynamic> body = {
        "phone": phoneController.text.trim(),
        "nickname": nickNameController.text.trim(),
        "companyName": companyController.text.trim(),
      };

      dynamic requestBody;
      if (pickedImage.value != null) {
        requestBody = dio.FormData.fromMap({
          ...body,
          "profilePicture": await dio.MultipartFile.fromFile(
            pickedImage.value!.path,
            filename: pickedImage.value!.path.split('/').last,
          ),
        });
      } else {
        requestBody = body;
      }

      var response = await _profileService.patchProfile(requestBody);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data?['success'] != false &&
          response.data?['data'] != null) {
        _applyProfileData(response.data['data']);
        pickedImage.value = null; // Clear picked image after success
        Get.back(); // Only close on actual success
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? "Profile updated successfully",
          isError: false,
        );
      } else {
        final errorMsg =
            response.data?['message'] ?? "Failed to update profile";
        Helpers.showCustomSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      String errorMsg = "Failed to update profile";
      if (e is dio.DioException && e.response?.data != null) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      Helpers.showCustomSnackBar(errorMsg, isError: true);
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    serviceAreaController.dispose();
    nickNameController.dispose();
    companyController.dispose();
    carTagController.dispose();
    zelleController.dispose();
    venmoController.dispose();
    cashAppController.dispose();
    super.onClose();
  }

  Future<bool> deleteAccount(String password) async {
    isUpdating.value = true;
    try {
      var response = await _profileService.deleteAccount(password);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        Helpers.showCustomSnackBar(
          response.data['message'] ?? "Failed to delete account",
          isError: true,
        );
        return false;
      }
    } catch (e) {
      debugPrint("Error deleting account: $e");
      Helpers.showCustomSnackBar(
        "Something went wrong while deleting account",
        isError: true,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
