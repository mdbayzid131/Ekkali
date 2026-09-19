import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moeb_26/core/utils/media_picker_helper.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/user_profile_model.dart';
import 'package:moeb_26/modules/auth/profile/controllers/profile_controller.dart';
import 'package:moeb_26/core/services/user_profile_service.dart';
import 'package:moeb_26/core/widgets/ImagePreviewPopup.dart';

class VehicleActionController extends GetxController {
  final UserProfileService _profileService = Get.find<UserProfileService>();
  final ImagePicker _imagePicker = ImagePicker();

  // Field controllers
  final makeController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final colorInsideController = TextEditingController();
  final colorOutsideController = TextEditingController();
  final licensePlateController = TextEditingController();
  final commercialInsuranceExpireController = TextEditingController();
  final vehicleRegistrationExpireController = TextEditingController();

  var selectedVehicleType = "".obs;
  var commercialInsuranceFile = Rx<File?>(null);
  var vehicleRegistrationFile = Rx<File?>(null);
  var frontViewFile = Rx<File?>(null);
  var rearViewFile = Rx<File?>(null);
  var interiorViewFile = Rx<File?>(null);

  // Existing image URLs from server (for eye-preview in edit mode)
  var commercialInsuranceUrl = RxnString();
  var vehicleRegistrationUrl = RxnString();
  var frontViewUrl = RxnString();
  var rearViewUrl = RxnString();
  var interiorViewUrl = RxnString();

  var isLoading = false.obs;
  var isEditMode = false.obs;
  String? editVehicleId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args['isEdit'] == true && args['vehicle'] != null) {
      isEditMode.value = true;
      final v = args['vehicle'] as Vehicle;
      editVehicleId = v.id;
      _populateVehicleData(v);
      if (editVehicleId != null && editVehicleId!.isNotEmpty) {
        _fetchFullVehicleDetails(editVehicleId!);
      }
    }
  }

  void _populateVehicleData(Vehicle v) {
    if (v.carType.isNotEmpty) selectedVehicleType.value = v.carType;
    if (v.make.isNotEmpty) makeController.text = v.make;
    if (v.model.isNotEmpty) modelController.text = v.model;
    if (v.year > 0) yearController.text = v.year.toString();
    if (v.colorInside.isNotEmpty) colorInsideController.text = v.colorInside;
    if (v.colorOutside.isNotEmpty) colorOutsideController.text = v.colorOutside;
    if (v.licensePlate.isNotEmpty) licensePlateController.text = v.licensePlate;

    if (v.commercialInsuranceExpiryDate != null &&
        v.commercialInsuranceExpiryDate!.isNotEmpty) {
      try {
        commercialInsuranceExpireController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(v.commercialInsuranceExpiryDate!));
      } catch (_) {
        commercialInsuranceExpireController.text =
            v.commercialInsuranceExpiryDate!;
      }
    }

    if (v.vehicleRegistrationExpiryDate != null &&
        v.vehicleRegistrationExpiryDate!.isNotEmpty) {
      try {
        vehicleRegistrationExpireController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(v.vehicleRegistrationExpiryDate!));
      } catch (_) {
        vehicleRegistrationExpireController.text =
            v.vehicleRegistrationExpiryDate!;
      }
    }

    if (v.commercialInsuranceImage != null &&
        v.commercialInsuranceImage!.isNotEmpty) {
      commercialInsuranceUrl.value = v.commercialInsuranceImage;
    }
    if (v.vehicleRegistrationImage != null &&
        v.vehicleRegistrationImage!.isNotEmpty) {
      vehicleRegistrationUrl.value = v.vehicleRegistrationImage;
    }
    if (v.vehiclePhotoFront != null && v.vehiclePhotoFront!.isNotEmpty) {
      frontViewUrl.value = v.vehiclePhotoFront;
    }
    if (v.vehiclePhotoRear != null && v.vehiclePhotoRear!.isNotEmpty) {
      rearViewUrl.value = v.vehiclePhotoRear;
    }
    if (v.vehiclePhotoInterior != null &&
        v.vehiclePhotoInterior!.isNotEmpty) {
      interiorViewUrl.value = v.vehiclePhotoInterior;
    }
  }

  Future<void> _fetchFullVehicleDetails(String vehicleId) async {
    try {
      final response = await _profileService.getVehicleById(vehicleId);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data is Map<String, dynamic>) {
          final fullVehicle = Vehicle.fromJson(data);
          _populateVehicleData(fullVehicle);
        }
      }
    } catch (e) {
      debugPrint("Error fetching full vehicle details for edit: $e");
    }
  }

  /// Shows the existing server image or the newly picked local file in a dialog.
  void previewImage(
    BuildContext context,
    Rx<File?> fileRx,
    RxnString urlRx, {
    String title = "Image Preview",
  }) {
    final localFile = fileRx.value;
    final serverUrl = urlRx.value;

    if (localFile == null && (serverUrl == null || serverUrl.isEmpty)) {
      Helpers.showCustomSnackBar(
        'No image available to preview.',
        isError: true,
      );
      return;
    }

    Get.dialog(
      ImagePreviewPopup(file: localFile, imageUrl: serverUrl, title: title),
    );
  }

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
          ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E2939)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
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

  String _formatDateToIso(String dateStr) {
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return trimmed;
    try {
      final parsed = DateTime.parse(trimmed);
      return parsed.toUtc().toIso8601String();
    } catch (_) {
      return trimmed;
    }
  }

  Future<void> submitVehicle() async {
    isLoading.value = true;
    try {
      final profileCtrl = Get.find<ProfileController>();
      final formData = dio.FormData();

      final make = makeController.text.trim();
      final model = modelController.text.trim();
      final makeAndModel = model.isNotEmpty ? "$make $model" : make;
      final rawPlate = licensePlateController.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

      formData.fields.addAll([
        MapEntry("type", selectedVehicleType.value),
        MapEntry("makeAndModel", makeAndModel),
        MapEntry("colorInside", colorInsideController.text.trim()),
        MapEntry("colorOutside", colorOutsideController.text.trim()),
        MapEntry("year", (int.tryParse(yearController.text.trim()) ?? 2024).toString()),
        MapEntry("licensePlate", licensePlateController.text.trim()),
        MapEntry("licensePlateRaw", rawPlate.isNotEmpty ? rawPlate : licensePlateController.text.trim()),
      ]);

      final regExpiry = _formatDateToIso(vehicleRegistrationExpireController.text);
      if (regExpiry.isNotEmpty) {
        formData.fields.add(MapEntry("vehicleRegistrationExpiryDate", regExpiry));
      }

      final insExpiry = _formatDateToIso(commercialInsuranceExpireController.text);
      if (insExpiry.isNotEmpty) {
        formData.fields.add(MapEntry("commercialInsuranceExpiryDate", insExpiry));
      }

      // Files
      if (vehicleRegistrationFile.value != null) {
        formData.files.add(
          MapEntry(
            'vehicleRegistrationImage',
            await dio.MultipartFile.fromFile(
              vehicleRegistrationFile.value!.path,
            ),
          ),
        );
      }
      if (commercialInsuranceFile.value != null) {
        formData.files.add(
          MapEntry(
            'commercialInsuranceImage',
            await dio.MultipartFile.fromFile(
              commercialInsuranceFile.value!.path,
            ),
          ),
        );
      }
      if (frontViewFile.value != null) {
        formData.files.add(
          MapEntry(
            'vehiclePhotoFront',
            await dio.MultipartFile.fromFile(frontViewFile.value!.path),
          ),
        );
      }
      if (rearViewFile.value != null) {
        formData.files.add(
          MapEntry(
            'vehiclePhotoRear',
            await dio.MultipartFile.fromFile(rearViewFile.value!.path),
          ),
        );
      }
      if (interiorViewFile.value != null) {
        formData.files.add(
          MapEntry(
            'vehiclePhotoInterior',
            await dio.MultipartFile.fromFile(interiorViewFile.value!.path),
          ),
        );
      }

      final dio.Response response;
      if (isEditMode.value && editVehicleId != null && editVehicleId!.isNotEmpty) {
        response = await _profileService.updateVehicle(editVehicleId!, formData);
      } else {
        response = await _profileService.addVehicle(formData);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data?['data'];
        if (data != null && data is Map<String, dynamic>) {
          final vehicle = Vehicle.fromJson(data);
          if (isEditMode.value) {
            final index = profileCtrl.vehiclesList.indexWhere((v) => v.id == vehicle.id);
            if (index != -1) {
              profileCtrl.vehiclesList[index] = vehicle;
            } else {
              profileCtrl.vehiclesList.add(vehicle);
            }
          } else {
            profileCtrl.vehiclesList.add(vehicle);
          }
        }

        Get.back(); // Navigate back
        Helpers.showCustomSnackBar(
          response.data?['message'] ??
              (isEditMode.value
                  ? "Vehicle updated successfully"
                  : "Vehicle added successfully"),
          isError: false,
        );
      } else {
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? "Failed to save vehicle",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Error submitting vehicle: $e");
      Helpers.showCustomSnackBar("Something went wrong", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    makeController.dispose();
    modelController.dispose();
    yearController.dispose();
    colorInsideController.dispose();
    colorOutsideController.dispose();
    licensePlateController.dispose();
    commercialInsuranceExpireController.dispose();
    vehicleRegistrationExpireController.dispose();
    super.onClose();
  }
}
