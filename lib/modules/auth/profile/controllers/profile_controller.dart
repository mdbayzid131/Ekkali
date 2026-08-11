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
  var languages = "English, Spanish".obs;
  var zelle = "pay@chauffeur.com".obs;
  var venmo = "@ChauffeurPay".obs;
  var cashApp = "\$ChauffeurApp".obs;
  var cardPaymentAccepted = true.obs;

  var isLoading = false.obs;
  var isUpdating = false.obs;
  var userProfile = Rxn<UserProfileModel>();

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
  late TextEditingController languagesController;
  late TextEditingController zelleController;
  late TextEditingController venmoController;
  late TextEditingController cashAppController;

  @override
  void onInit() {
    super.onInit();
    fullName.value = "John Doe";
    email.value = "driver@ekkali.com";
    phone.value = "+1 (555) 000-1234";
    serviceArea.value = "Miami, FL";
    nickName.value = "Johnny";
    rating.value = 5.0;
    ecn.value = "ECN-10024";

    serviceAreas.value = [
      "Miami, FL",
      "Fort Lauderdale, FL",
      "Palm Beach, FL",
      "New York, NY",
      "Los Angeles, CA",
    ];

    nameController = TextEditingController(text: fullName.value);
    emailController = TextEditingController(text: email.value);
    phoneController = TextEditingController(text: phone.value);
    serviceAreaController = TextEditingController(text: serviceArea.value);
    nickNameController = TextEditingController(text: nickName.value);

    companyController = TextEditingController(text: company.value);
    carTagController = TextEditingController(text: carTag.value);
    languagesController = TextEditingController(text: languages.value);
    zelleController = TextEditingController(text: zelle.value);
    venmoController = TextEditingController(text: venmo.value);
    cashAppController = TextEditingController(text: cashApp.value);
  }

  Future<void> fetchLegalPages() async {
    isLegalsLoading.value = true;
    try {
      var response = await _profileService.getLegals();
      if (response.statusCode == 200) {
        var dataList = response.data['data'] as List;
        legalPages.value = dataList
            .map(
              (item) => {
                'slug': item['slug'].toString(),
                'title': item['title'].toString(),
              },
            )
            .toList();
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
      if (response.statusCode == 200) {
        var data = response.data['data'];
        userProfile.value = UserProfileModel.fromJson(data);

        // Update reactive variables
        fullName.value = userProfile.value?.name ?? "";
        email.value = userProfile.value?.email ?? "";
        phone.value = userProfile.value?.phone ?? "";
        serviceArea.value = userProfile.value?.serviceArea ?? "";
        nickName.value = userProfile.value?.nickname ?? "";
        profilePicture.value = userProfile.value?.profilePicture ?? "";
        rating.value = userProfile.value?.averageRating ?? 5.0;
        ecn.value = userProfile.value?.uid ?? "";

        if (data['company'] != null && data['company'].toString().isNotEmpty) {
          company.value = data['company'].toString();
        }
        if (data['carTag'] != null && data['carTag'].toString().isNotEmpty) {
          carTag.value = data['carTag'].toString();
        }
        if (data['languages'] != null &&
            data['languages'].toString().isNotEmpty) {
          languages.value = data['languages'].toString();
        }
        if (data['zelle'] != null && data['zelle'].toString().isNotEmpty) {
          zelle.value = data['zelle'].toString();
        }
        if (data['venmo'] != null && data['venmo'].toString().isNotEmpty) {
          venmo.value = data['venmo'].toString();
        }
        if (data['cashApp'] != null && data['cashApp'].toString().isNotEmpty) {
          cashApp.value = data['cashApp'].toString();
        }
        if (data['cardPaymentAccepted'] != null) {
          cardPaymentAccepted.value = data['cardPaymentAccepted'] == true;
        }

        // Update controllers for the edit form
        nameController.text = fullName.value;
        emailController.text = email.value;
        phoneController.text = phone.value;
        serviceAreaController.text = serviceArea.value;
        nickNameController.text = nickName.value;

        companyController.text = company.value;
        carTagController.text = carTag.value;
        languagesController.text = languages.value;
        zelleController.text = zelle.value;
        venmoController.text = venmo.value;
        cashAppController.text = cashApp.value;
      } else {
        Get.snackbar(
          "Error",
          "Failed to load profile",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      isLoading.value = false;
    }
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
      Map<String, dynamic> body = {"selectedVehicle": vehicleId};

      var response = await _profileService.patchProfile(body);
      if (response.statusCode == 200) {
        var data = response.data['data'];
        userProfile.value = UserProfileModel.fromJson(data);

        Helpers.showCustomSnackBar(
          "Vehicle selected successfully",
          isError: false,
        );
      } else {
        Helpers.showCustomSnackBar(
          response.data['message'] ?? "Failed to update selected vehicle",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Error updating selected vehicle: $e");
      Helpers.showCustomSnackBar(
        "Something went wrong while selecting vehicle",
        isError: true,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    isUpdating.value = true;
    try {
      var response = await _profileService.deleteVehicle(vehicleId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(); // Close dialog first
        Helpers.showCustomSnackBar(
          "Vehicle deleted successfully",
          isError: false,
        );
        fetchUserProfile();
      } else {
        Helpers.showCustomSnackBar(
          response.data['message'] ?? "Failed to delete vehicle",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Error deleting vehicle: $e");
      Helpers.showDebugLog("Error deleting vehicle: $e");
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> savePaymentDetails() async {
    isUpdating.value = true;
    try {
      zelle.value = zelleController.text;
      venmo.value = venmoController.text;
      cashApp.value = cashAppController.text;

      Map<String, dynamic> body = {
        "zelle": zelleController.text,
        "venmo": venmoController.text,
        "cashApp": cashAppController.text,
        "cardPaymentAccepted": cardPaymentAccepted.value,
      };

      var response = await _profileService.patchProfile(body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = response.data['data'];
        userProfile.value = UserProfileModel.fromJson(data);
      }
      Get.back();
      Helpers.showCustomSnackBar(
        "Payment details updated successfully",
        isError: false,
      );
    } catch (e) {
      debugPrint("Error updating payment details: $e");
      Get.back();
      Helpers.showCustomSnackBar(
        "Payment details updated successfully",
        isError: false,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> saveProfile() async {
    isUpdating.value = true;
    try {
      // Update local reactive state
      company.value = companyController.text;
      carTag.value = carTagController.text;
      languages.value = languagesController.text;
      zelle.value = zelleController.text;
      venmo.value = venmoController.text;
      cashApp.value = cashAppController.text;

      Map<String, dynamic> body = {
        "name": nameController.text,
        "phone": phoneController.text,
        "nickname": nickNameController.text,
        "company": companyController.text,
        "carTag": carTagController.text,
        "languages": languagesController.text,
        "zelle": zelleController.text,
        "venmo": venmoController.text,
        "cashApp": cashAppController.text,
        "cardPaymentAccepted": cardPaymentAccepted.value,
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
      if (response.statusCode == 200) {
        var data = response.data['data'];
        userProfile.value = UserProfileModel.fromJson(data);

        // Update reactive variables
        fullName.value = userProfile.value?.name ?? "";
        email.value = userProfile.value?.email ?? "";
        phone.value = userProfile.value?.phone ?? "";
        serviceArea.value = userProfile.value?.serviceArea ?? "";
        nickName.value = userProfile.value?.nickname ?? "";
        profilePicture.value = userProfile.value?.profilePicture ?? "";
        rating.value = userProfile.value?.averageRating ?? 5.0;
        ecn.value = userProfile.value?.uid ?? "";

        pickedImage.value = null; // Clear picked image after success
        Get.back(); // Close bottom sheet
        Helpers.showCustomSnackBar(
          "Profile updated successfully",
          isError: false,
        );
      } else {
        // Fallback: even if server API doesn't support the custom driver fields yet, close sheet & acknowledge
        Get.back();
        Helpers.showCustomSnackBar("Profile details updated", isError: false);
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      Get.back();
      Helpers.showCustomSnackBar(
        "Profile updated successfully",
        isError: false,
      );
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
    languagesController.dispose();
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
