import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/data/models/vehicle_model.dart';
import 'package:moeb_26/core/services/api_client.dart';

class AuthRepo {
  final ApiClient apiClient;
  AuthRepo({required this.apiClient});

  // Future<String> getDeviceId() async {
  //   final deviceInfo = DeviceInfoPlugin();
  //
  //   if (Platform.isAndroid) {
  //     final androidInfo = await deviceInfo.androidInfo;
  //     return androidInfo.id; // অথবা androidInfo.device, androidInfo.model
  //   } else if (Platform.isIOS) {
  //     final iosInfo = await deviceInfo.iosInfo;
  //     return iosInfo.identifierForVendor ?? "unknown";
  //   } else {
  //     return "unsupported";
  //   }
  // }

  /// ===================== SIGNUP (CLEAN & SIMPLE) =====================
  Future<Response<dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String serviceAreaId,
    required String companyName,
    required String companyRole,
  }) async {
    return await apiClient.postData(ApiConstants.signup, {
      "name": name,
      "email": email,
      "password": password,
      "phone": phone,
      "serviceAreaId": serviceAreaId,
      "companyName": companyName,
      "companyRole": companyRole,
    });
  }

  /// ===================== VEHICLE SETUP (SEPARATE API) =====================
  Future<Response<dynamic>> addVehicle({
    required List<VehicleModel> vehicles,
  }) async {
    final formData = FormData();

    if (vehicles.length == 1) {
      final v = vehicles.first;
      final make = v.makeController.text.trim();
      final model = v.modelController.text.trim();
      final makeAndModel = make.isNotEmpty && model.isNotEmpty
          ? '$make $model'
          : (make.isNotEmpty ? make : model);
      final rawPlate = v.licensePlateController.text
          .replaceAll('-', '')
          .replaceAll(' ', '');

      final vehicleData = {
        "makeAndModel": makeAndModel.isEmpty ? 'Vehicle 1' : makeAndModel,
        "year": int.tryParse(v.yearController.text) ?? 2023,
        "licensePlate": v.licensePlateController.text,
        "type": v.selectedVehicleType.value.isEmpty
            ? 'Sedan'
            : v.selectedVehicleType.value,
        "colorInside": v.colorInsideController.text,
        "colorOutside": v.colorOutsideController.text,
        "licensePlateRaw":
            rawPlate.isEmpty ? v.licensePlateController.text : rawPlate,
        "vehicleRegistrationExpiryDate":
            v.vehicleRegistrationExpireController.text,
        "commercialInsuranceExpiryDate":
            v.commercialInsuranceExpireController.text,
      };

      formData.fields.add(MapEntry('data', jsonEncode(vehicleData)));

      if (v.vehicleRegistrationFile.value != null) {
        formData.files.add(
          MapEntry(
            'vehicleRegistrationImage',
            await MultipartFile.fromFile(
              v.vehicleRegistrationFile.value!.path,
            ),
          ),
        );
      }
      if (v.commercialInsuranceFile.value != null) {
        formData.files.add(
          MapEntry(
            'commercialInsuranceImage',
            await MultipartFile.fromFile(
              v.commercialInsuranceFile.value!.path,
            ),
          ),
        );
      }
      if (v.frontViewFile.value != null) {
        formData.files.add(
          MapEntry(
            'vehiclePhotoFront',
            await MultipartFile.fromFile(v.frontViewFile.value!.path),
          ),
        );
      }
      if (v.rearViewFile.value != null) {
        formData.files.add(
          MapEntry(
            'vehiclePhotoRear',
            await MultipartFile.fromFile(v.rearViewFile.value!.path),
          ),
        );
      }
      if (v.interiorViewFile.value != null) {
        formData.files.add(
          MapEntry(
            'vehiclePhotoInterior',
            await MultipartFile.fromFile(v.interiorViewFile.value!.path),
          ),
        );
      }
    } else {
      // Multiple vehicles sent in ONE single API request (Scenario 5.3B)
      final List<Map<String, dynamic>> vehiclesJson = [];

      for (int i = 0; i < vehicles.length; i++) {
        final v = vehicles[i];
        final make = v.makeController.text.trim();
        final model = v.modelController.text.trim();
        final makeAndModel = make.isNotEmpty && model.isNotEmpty
            ? '$make $model'
            : (make.isNotEmpty ? make : model);
        final rawPlate = v.licensePlateController.text
            .replaceAll('-', '')
            .replaceAll(' ', '');

        vehiclesJson.add({
          "makeAndModel":
              makeAndModel.isEmpty ? 'Vehicle ${i + 1}' : makeAndModel,
          "year": int.tryParse(v.yearController.text) ?? 2023,
          "licensePlate": v.licensePlateController.text,
          "type": v.selectedVehicleType.value.isEmpty
              ? 'Sedan'
              : v.selectedVehicleType.value,
          "colorInside": v.colorInsideController.text,
          "colorOutside": v.colorOutsideController.text,
          "licensePlateRaw":
              rawPlate.isEmpty ? v.licensePlateController.text : rawPlate,
          "vehicleRegistrationExpiryDate":
              v.vehicleRegistrationExpireController.text,
          "commercialInsuranceExpiryDate":
              v.commercialInsuranceExpireController.text,
        });

        if (v.vehicleRegistrationFile.value != null) {
          formData.files.add(
            MapEntry(
              'vehicleRegistrationImage',
              await MultipartFile.fromFile(
                v.vehicleRegistrationFile.value!.path,
              ),
            ),
          );
        }
        if (v.commercialInsuranceFile.value != null) {
          formData.files.add(
            MapEntry(
              'commercialInsuranceImage',
              await MultipartFile.fromFile(
                v.commercialInsuranceFile.value!.path,
              ),
            ),
          );
        }
        if (v.frontViewFile.value != null) {
          formData.files.add(
            MapEntry(
              'vehiclePhotoFront',
              await MultipartFile.fromFile(v.frontViewFile.value!.path),
            ),
          );
        }
        if (v.rearViewFile.value != null) {
          formData.files.add(
            MapEntry(
              'vehiclePhotoRear',
              await MultipartFile.fromFile(v.rearViewFile.value!.path),
            ),
          );
        }
        if (v.interiorViewFile.value != null) {
          formData.files.add(
            MapEntry(
              'vehiclePhotoInterior',
              await MultipartFile.fromFile(v.interiorViewFile.value!.path),
            ),
          );
        }
      }

      formData.fields.add(MapEntry('data', jsonEncode(vehiclesJson)));
    }

    return await apiClient.postData(ApiConstants.vehicles, formData);
  }

  String _formatDateToIso(String dateStr) {
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return trimmed;
    try {
      final parsed = DateFormat('dd MMMM yyyy').parse(trimmed);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat('d MMMM yyyy').parse(trimmed);
        return DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {
        return trimmed;
      }
    }
  }

  /// Uploads a single document to POST /api/v1/documents
  Future<Response<dynamic>> _uploadSingleDocument({
    required String documentType,
    required File file,
    String? expiryDate,
  }) async {
    final formData = FormData();

    final Map<String, dynamic> docMap = {
      "documentType": documentType,
    };
    if (expiryDate != null && expiryDate.trim().isNotEmpty) {
      docMap["expiryDate"] = _formatDateToIso(expiryDate);
    }

    formData.fields.add(MapEntry('data', jsonEncode(docMap)));
    formData.files.add(
      MapEntry(
        'file',
        await MultipartFile.fromFile(file.path),
      ),
    );

    return await apiClient.postData(ApiConstants.documents, formData);
  }

  bool _isSuccessResponse(Response response) {
    final code = response.statusCode ?? 0;
    return (code >= 200 && code < 300) || response.data?['success'] == true;
  }

  /// ===================== DOCUMENTS UPLOAD (SEQUENTIAL) =====================
  Future<Response<dynamic>> uploadDocuments({
    required File drivingLicenseFile,
    required String drivingLicenseExpiry,
    required File hackLicenseFile,
    required String hackLicenseExpiry,
    File? localPermitFile,
    String? localPermitExpiry,
    required File headshotFile,
  }) async {
    // 1. DRIVING_LICENSE
    var response = await _uploadSingleDocument(
      documentType: "DRIVING_LICENSE",
      file: drivingLicenseFile,
      expiryDate: drivingLicenseExpiry,
    );
    if (!_isSuccessResponse(response)) {
      return response;
    }

    // 2. HACK_LICENSE
    response = await _uploadSingleDocument(
      documentType: "HACK_LICENSE",
      file: hackLicenseFile,
      expiryDate: hackLicenseExpiry,
    );
    if (!_isSuccessResponse(response)) {
      return response;
    }

    // 3. LOCAL_PERMIT (Optional)
    if (localPermitFile != null) {
      response = await _uploadSingleDocument(
        documentType: "LOCAL_PERMIT",
        file: localPermitFile,
        expiryDate: localPermitExpiry,
      );
      if (!_isSuccessResponse(response)) {
        return response;
      }
    }

    // 4. PROFILE_PICTURE
    response = await _uploadSingleDocument(
      documentType: "PROFILE_PICTURE",
      file: headshotFile,
    );

    return response;
  }

  /// ===================== LOGIN =====================
  Future<Response> login({
    required String email,
    required String password,
    String? deviceToken,
  }) async {
    return await apiClient.postData(ApiConstants.login, {
      "email": email,
      "password": password,
      "deviceToken": deviceToken ?? '',
    });
  }

  /// ===================== FORGOT PASSWORD =====================
  Future<Response> forgotPassword({required String email}) async {
    return await apiClient.postData(ApiConstants.forgotPassword, {
      "email": email,
    });
  }

  /// ===================== RESEND OTP =====================
  Future<Response> resentOtp({required String email}) async {
    return await apiClient.postData(ApiConstants.resendOtp, {
      "email": email,
    });
  }

  Future<Response> resendOtp({required String email}) async {
    return await resentOtp(email: email);
  }

  /// ===================== OTP VERIFY =====================
  Future<Response> otpVerify({
    required String email,
    required int oneTimeCode,
  }) async {
    return await apiClient.postData(ApiConstants.verifyEmail, {
      "email": email,
      "oneTimeCode": oneTimeCode,
    });
  }

  /// ===================== RESET PASSWORD =====================
  Future<Response> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await apiClient.postData(ApiConstants.resetPassword, {
      "newPassword": newPassword,
      "confirmPassword": confirmPassword,
    }, resetToken: resetToken);
  }

  /// ===================== LOGOUT =====================
  Future<Response> logout({String? deviceToken}) async {
    return await apiClient.postData(ApiConstants.logout, {
      "deviceToken": deviceToken ?? '',
    });
  }

  /// ===================== REFRESH TOKEN =====================
  Future<Response> refreshToken(String refreshToken) async {
    return await apiClient.postData(ApiConstants.refreshToken, {
      "refreshToken": refreshToken,
    });
  }

  /// ===================== CHANGE PASSWORD =====================
  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await apiClient.postData(ApiConstants.changePassword, {
      "currentPassword": currentPassword,
      "newPassword": newPassword,
      "confirmPassword": confirmPassword,
    });
  }
}
