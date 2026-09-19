import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_picker/image_picker.dart';
import 'package:moeb_26/core/utils/media_picker_helper.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/vehicle_model.dart';
import 'package:moeb_26/modules/service_Area/controllers/serviceController.dart';
import 'package:moeb_26/core/services/auth_service.dart';

class SignupController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ImagePicker _imagePicker = ImagePicker();

  final ServiceAreaController _serviceAreaController =
      Get.isRegistered<ServiceAreaController>()
      ? Get.find<ServiceAreaController>()
      : Get.put(ServiceAreaController());

  var isLoading = false.obs;
  var showErrors = false.obs;

  @override
  void onInit() {
    super.onInit();
    showErrors.value = false;
    vehiclesList = <VehicleModel>[VehicleModel()].obs;
  }

  // ===========================================================================
  // STEP 1: ACCOUNT INFORMATION
  // ===========================================================================
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final yearController = TextEditingController();
  final companyNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var showPassword = false.obs;
  var showConfirmPassword = false.obs;
  var selectedRole = ''.obs;
  var selectedArea = ''.obs;
  var selectedAreaId = ''.obs;

  final roles = ['Company manager', 'Owner operator', 'Chauffeur'];

  // Service Area data
  List<String> get cities => _serviceAreaController.serviceAreas
      .map((e) => e.areaName)
      .toSet()
      .toList();
  bool get isCitiesLoading => _serviceAreaController.isLoading.value;
  bool get isMoreCitiesLoading => _serviceAreaController.isMoreLoading.value;
  bool get hasNextCitiesPage => _serviceAreaController.hasMore.value;

  void togglePassword() => showPassword.value = !showPassword.value;
  void toggleConfirmPassword() =>
      showConfirmPassword.value = !showConfirmPassword.value;

  void pickRole(String role) => selectedRole.value = role;
  void pickArea(String areaName) {
    selectedArea.value = areaName;
    // Resolve the corresponding serviceAreaId from the loaded areas list
    try {
      final match = _serviceAreaController.serviceAreas.firstWhere(
        (e) => e.areaName == areaName,
      );
      selectedAreaId.value = match.id;
    } catch (_) {
      selectedAreaId.value = '';
    }
  }

  void fetchServiceAreas() => _serviceAreaController.fetchServiceAreas();
  void loadMoreCities() => _serviceAreaController.loadMoreServiceAreas();

  // ===========================================================================
  // STEP 2: VEHICLE INFORMATION
  // ===========================================================================
  late RxList<VehicleModel> vehiclesList;

  void addVehicle() {
    // Small async gap ensures microsecond-based VehicleModel.id is always unique
    Future.microtask(() => vehiclesList.add(VehicleModel()));
  }

  void removeVehicle(int index) {
    if (vehiclesList.length > 1) {
      final removed = vehiclesList.removeAt(index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        removed.dispose();
      });
    }
  }

  // ===========================================================================
  // STEP 3: DOCUMENTS UPLOAD
  // ===========================================================================
  final Rx<File?> licensePlateFile = Rx<File?>(null);
  final Rx<File?> hackLicenseFile = Rx<File?>(null);
  final Rx<File?> localPermitFile = Rx<File?>(null);
  final Rx<File?> headshotFile = Rx<File?>(null);
  final Rx<File?> profilePictureFile = Rx<File?>(null);

  final licensePlateExpireController = TextEditingController();
  final hackLicenseExpireController = TextEditingController();
  final localPermitExpireController = TextEditingController();

  // ===========================================================================
  // STEP 4: TERMS & POLICY
  // ===========================================================================
  final RxList<bool> termChecks = List.generate(65, (_) => false).obs;
  final RxBool showTermError = false.obs;

  void toggleTermCheck(int index) {
    termChecks[index] = !termChecks[index];
    if (allTermsChecked) showTermError.value = false;
  }

  bool get allTermsChecked => termChecks.every((e) => e);

  // ===========================================================================
  // HELPER METHODS (MEDIA & DATE)
  // ===========================================================================

  Future<void> selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF14F195),
            onPrimary: Colors.black,
            surface: Color(0xFF1E2939),
            onSurface: Colors.white,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF1E2939),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text = DateFormat('d MMMM y').format(picked);
    }
  }

  bool _isPicking = false;

  Future<void> pickFromCamera(Rx<File?> target) async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        final file = File(image.path);
        final originalSize = await file.length();
        Helpers.debug(
          'Original Camera Image Size: ${(originalSize / 1024).toStringAsFixed(2)} KB',
        );

        final compressed = await Helpers.compressImage(file);
        final fileSize = await compressed.length();
        Helpers.debug(
          'Compressed Camera Image Size: ${(fileSize / 1024).toStringAsFixed(2)} KB',
        );

        if (fileSize > 1024 * 1024) {
          Helpers.showCustomSnackBar(
            'Maximum file size allowed is 1MB',
            isError: true,
          );
          return;
        }
        target.value = compressed;
      }
    } catch (e) {
      Helpers.error('Error picking from camera: $e');
      Helpers.showCustomSnackBar(
        'Could not open camera. Please check app permissions in settings.',
        isError: true,
      );
    } finally {
      _isPicking = false;
    }
  }

  Future<void> pickFromGallery(BuildContext context, Rx<File?> target) async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final File? file = await MediaPickerHelper.pickSingleImage(context);
      if (file != null) {
        final compressed = await Helpers.compressImage(file);
        final fileSize = await compressed.length();
        if (fileSize > 1024 * 1024) {
          Helpers.showCustomSnackBar(
            'Maximum file size allowed is 1MB',
            isError: true,
          );
          return;
        }
        target.value = compressed;
      }
    } catch (e) {
      Helpers.error('Error picking from gallery: $e');
    } finally {
      _isPicking = false;
    }
  }

  Future<void> pickFromFile(BuildContext context, Rx<File?> target) async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final File? file = await MediaPickerHelper.showImageOrPdfPicker(context);
      if (file != null) {
        final path = file.path.toLowerCase();
        final isImage = !path.endsWith('.pdf');

        if (isImage) {
          final compressed = await Helpers.compressImage(file);
          final fileSize = await compressed.length();
          if (fileSize > 1024 * 1024) {
            Helpers.showCustomSnackBar(
              'Maximum file size allowed is 1MB',
              isError: true,
            );
            return;
          }
          target.value = compressed;
        } else {
          final fileSize = await file.length();
          if (fileSize > 1024 * 1024) {
            Helpers.showCustomSnackBar(
              'Maximum file size allowed is 1MB',
              isError: true,
            );
            return;
          }
          target.value = file;
        }
      }
    } catch (e) {
      Helpers.error('Error picking from file: $e');
    } finally {
      _isPicking = false;
    }
  }

  String getFileName(Rx<File?> file) {
    if (file.value == null) return '';
    final name = file.value!.path.split('/').last.split('\\').last;
    if (name.length > 20) {
      final extIndex = name.lastIndexOf('.');
      final ext = extIndex != -1 ? name.substring(extIndex) : '';
      final base = extIndex != -1 ? name.substring(0, extIndex) : name;
      if (base.length > 12) {
        return '${base.substring(0, 7)}...${base.substring(base.length - 4)}$ext';
      }
    }
    return name;
  }

  // ===========================================================================
  // STEP 2 SUBMIT — TERMS & CONDITIONS -> OTP
  // ===========================================================================
  Future<void> submitTermsAndContinue() async {
    if (!allTermsChecked) {
      showTermError.value = true;
      Helpers.showCustomSnackBar(
        'Please agree to all terms before continuing',
        isError: true,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Map role to backend enum format: 'Company Manager' | 'Owner' | 'Operator' | 'Chauffeur'
      String roleToSubmit = selectedRole.value;
      final roleLower = roleToSubmit.toLowerCase();
      if (roleLower == 'company manager') {
        roleToSubmit = 'Company Manager';
      } else if (roleLower == 'owner operator' || roleLower == 'owner') {
        roleToSubmit = 'Owner';
      } else if (roleLower == 'operator') {
        roleToSubmit = 'Operator';
      } else if (roleLower == 'chauffeur' || roleLower == 'driver') {
        roleToSubmit = 'Chauffeur';
      }

      // Call simplified signup API (clean JSON payload)
      final response = await _authService.signup(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        phone: phoneController.text,
        serviceAreaId: selectedAreaId.value,
        companyName: companyNameController.text,
        companyRole: roleToSubmit,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showCustomSnackBar('Registration successful', isError: false);
        Get.toNamed(
          Routes.otpVerificationView,
          arguments: {'email': emailController.text, 'isRegister': true},
        );
      } else {
        final message = _extractErrorMessage(response);
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      // Fallback navigation for offline / dev mock testing
      Get.toNamed(
        Routes.otpVerificationView,
        arguments: {'email': emailController.text, 'isRegister': true},
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Alias for backward compatibility
  Future<void> submitAll() => submitTermsAndContinue();

  /// Validates Vehicle Information form and navigates to Document Upload View (without calling API yet)
  Future<void> submitVehicleInfo() async {
    showErrors.value = true;
    for (int i = 0; i < vehiclesList.length; i++) {
      final v = vehiclesList[i];
      if (v.selectedVehicleType.value.isEmpty ||
          (v.makeController.text.trim().isEmpty &&
              v.modelController.text.trim().isEmpty) ||
          v.colorInsideController.text.trim().isEmpty ||
          v.colorOutsideController.text.trim().isEmpty ||
          v.yearController.text.trim().isEmpty ||
          v.licensePlateController.text.trim().isEmpty ||
          v.commercialInsuranceFile.value == null ||
          v.commercialInsuranceExpireController.text.trim().isEmpty ||
          v.vehicleRegistrationFile.value == null ||
          v.vehicleRegistrationExpireController.text.trim().isEmpty ||
          v.frontViewFile.value == null ||
          v.rearViewFile.value == null ||
          v.interiorViewFile.value == null) {
        return;
      }
    }

    Get.toNamed(Routes.documentsuploadView);
  }

  // ===========================================================================
  // POST-OTP ACCOUNT SETUP SUBMIT — HITS VEHICLE & DOCUMENTS APIS SEQUENTIALLY
  // ===========================================================================
  Future<void> submitAccountSetup() async {
    showErrors.value = true;
    if (licensePlateFile.value == null ||
        licensePlateExpireController.text.trim().isEmpty ||
        hackLicenseFile.value == null ||
        hackLicenseExpireController.text.trim().isEmpty ||
        localPermitFile.value == null ||
        localPermitExpireController.text.trim().isEmpty ||
        profilePictureFile.value == null) {
      return;
    }

    try {
      isLoading.value = true;

      // 1. Call Vehicle API first
      final vehicleResponse = await _authService.addVehicle(
        vehicles: vehiclesList.toList(),
      );

      final vehicleCode = vehicleResponse.statusCode ?? 0;
      final isVehicleSuccess = (vehicleCode >= 200 && vehicleCode < 300) ||
          vehicleResponse.data?['success'] == true;

      if (!isVehicleSuccess) {
        final msg = _extractErrorMessage(vehicleResponse);
        Helpers.showCustomSnackBar(
          'Vehicle submission failed: $msg',
          isError: true,
        );
        return;
      }

      // 2. Call Document Upload API second
      final docResponse = await _authService.uploadDocuments(
        drivingLicenseFile: licensePlateFile.value!,
        drivingLicenseExpiry: licensePlateExpireController.text,
        hackLicenseFile: hackLicenseFile.value!,
        hackLicenseExpiry: hackLicenseExpireController.text,
        localPermitFile: localPermitFile.value,
        localPermitExpiry: localPermitExpireController.text.isEmpty
            ? null
            : localPermitExpireController.text,
        headshotFile: profilePictureFile.value!,
      );

      final docCode = docResponse.statusCode ?? 0;
      final isDocSuccess = (docCode >= 200 && docCode < 300) ||
          docResponse.data?['success'] == true;

      if (!isDocSuccess) {
        final msg = _extractErrorMessage(docResponse);
        Helpers.showCustomSnackBar(
          'Document upload failed: $msg',
          isError: true,
        );
        return;
      }

      Helpers.showCustomSnackBar(
        'Account setup submitted for review',
        isError: false,
      );
      Get.offAllNamed(Routes.applicationSubmitedView);
    } catch (e) {
      Helpers.showCustomSnackBar(
        'Submission error: ${_extractErrorMessage(e)}',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Extracts error message dynamically from a Dio response or exception
  String _extractErrorMessage(dynamic errorOrResponse) {
    if (errorOrResponse == null) return 'Registration failed.';

    if (errorOrResponse is DioException) {
      if (errorOrResponse.response?.statusCode == 413) {
        return 'Your uploaded file is too large!';
      }
      final data = errorOrResponse.response?.data;
      return _parseData(data) ??
          errorOrResponse.message ??
          'Registration failed.';
    }

    if (errorOrResponse is Response) {
      if (errorOrResponse.statusCode == 413) {
        return 'Your uploaded file is too large!';
      }
      final data = errorOrResponse.data;
      return _parseData(data) ??
          errorOrResponse.statusMessage ??
          'Registration failed.';
    }

    return 'Registration failed.';
  }

  /// Parses various error formats from the API response
  String? _parseData(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      // 1. Check 'errorMessages' array (Zod validation errors)
      final errorMessages = data['errorMessages'];
      if (errorMessages is List && errorMessages.isNotEmpty) {
        final messages = errorMessages.map((e) {
          if (e is Map && e['message'] != null) {
            return e['message'].toString();
          }
          return e.toString();
        }).toList();
        return messages.join('\n');
      }

      // 2. Check 'message' key
      final message = data['message'];
      if (message != null) {
        if (message is List) {
          return message.join('\n');
        }
        return message.toString();
      }

      // 2. Check 'error' key
      final error = data['error'];
      if (error != null) {
        if (error is List) {
          return error.join('\n');
        }
        return error.toString();
      }

      // 3. Check 'errors' key
      final errors = data['errors'];
      if (errors != null) {
        if (errors is Map) {
          final messages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              messages.add("$key: ${value.join(', ')}");
            } else {
              messages.add("$key: $value");
            }
          });
          return messages.join('\n');
        } else if (errors is List) {
          return errors.join('\n');
        }
        return errors.toString();
      }
    } else if (data is String && data.isNotEmpty) {
      return data;
    }
    return null;
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    yearController.dispose();
    companyNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    licensePlateExpireController.dispose();
    hackLicenseExpireController.dispose();
    localPermitExpireController.dispose();
    for (var v in vehiclesList) {
      v.dispose();
    }
    super.onClose();
  }
}
