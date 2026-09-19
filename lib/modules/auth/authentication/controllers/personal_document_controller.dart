import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/utils/media_picker_helper.dart';
import 'package:moeb_26/core/widgets/ImagePreviewPopup.dart';
import 'package:moeb_26/data/models/compliance_document_model.dart';
import 'package:moeb_26/data/repositories/compliance_document_repository.dart';

/// Standalone controller for Compliance Documents
class PersonalDocumentController extends GetxController {
  final ImagePicker _imagePicker = ImagePicker();
  late final ComplianceDocumentRepository _documentRepo;

  PersonalDocumentController() {
    _documentRepo = Get.isRegistered<ComplianceDocumentRepository>()
        ? Get.find<ComplianceDocumentRepository>()
        : Get.put(
            ComplianceDocumentRepository(apiClient: Get.find<ApiClient>()),
            permanent: true,
          );
  }

  final isLoading = false.obs;

  // Document IDs from server (for PATCH /api/v1/documents/:id)
  final drivingLicenseId = RxnString();
  final hackLicenseId = RxnString();
  final localPermitId = RxnString();

  // Document Statuses from server
  final drivingLicenseStatus = RxnString();
  final hackLicenseStatus = RxnString();
  final localPermitStatus = RxnString();

  // Individual Card Loading States
  final isUpdatingDrivingLicense = false.obs;
  final isUpdatingHackLicense = false.obs;
  final isUpdatingLocalPermit = false.obs;

  // RX variables for newly picked local files
  final drivingLicenseFile = Rx<File?>(null);
  final hackLicenseFile = Rx<File?>(null);
  final localPermitFile = Rx<File?>(null);

  // Existing image/file URLs from server
  final drivingLicenseUrl = RxnString();
  final hackLicenseUrl = RxnString();
  final localPermitUrl = RxnString();

  // Controllers & Reactive Expiry Dates
  final drivingLicenseExpireController = TextEditingController();
  final hackLicenseExpireController = TextEditingController();
  final localPermitExpireController = TextEditingController();

  final drivingLicenseExpiry = ''.obs;
  final hackLicenseExpiry = ''.obs;
  final localPermitExpiry = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadExistingDocuments();
  }

  Future<void> fetchDocuments() => _loadExistingDocuments();

  /// 1. GET /api/v1/documents/licenses
  Future<void> _loadExistingDocuments() async {
    isLoading.value = true;
    try {
      final response = await _documentRepo.getComplianceDocuments();
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['data'] is List) {
        final List list = response.data['data'];
        for (var item in list) {
          if (item is Map) {
            final doc = ComplianceDocumentModel.fromJson(
              Map<String, dynamic>.from(item),
            );
            _applyDocState(doc.documentType, doc);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching compliance documents: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 2. Save (Update or Upload) compliance document
  Future<void> updateSingleDocument(String documentType) async {
    final title = _getTitle(documentType);
    final docIdRx = _getDocIdRx(documentType);
    final fileRx = _getFileRx(documentType);
    final expireController = _getExpireController(documentType);
    final isUpdatingRx = _getIsUpdatingRx(documentType);

    final docId = docIdRx.value;
    final file = fileRx.value;
    final expiryText = expireController.text.trim();

    // Strict Validation: Expiration date is mandatory
    if (expiryText.isEmpty) {
      Helpers.showCustomSnackBar(
        'Please select the official expiration date for $title.',
        isError: true,
      );
      return;
    }

    // New upload requires a file
    if ((docId == null || docId.isEmpty) && file == null) {
      Helpers.showCustomSnackBar(
        'Please attach a document file (Photo or PDF) to upload $title.',
        isError: true,
      );
      return;
    }

    try {
      isUpdatingRx.value = true;

      // Call PATCH if exists, or POST if new
      final response = (docId != null && docId.isNotEmpty)
          ? await _documentRepo.updateDocument(
              documentId: docId,
              expiryDate: expiryText.isNotEmpty ? expiryText : null,
              file: file,
            )
          : await _documentRepo.uploadDocument(
              documentType: documentType,
              file: file!,
              expiryDate: expiryText.isNotEmpty ? expiryText : null,
            );

      final code = response.statusCode ?? 0;
      final isSuccess =
          (code >= 200 && code < 300) || response.data?['success'] == true;

      if (isSuccess) {
        fileRx.value = null; // Clear local picked file

        // Extract response data (supports both Map and List responses)
        final rawData = response.data?['data'];
        Map<String, dynamic>? docMap;
        if (rawData is Map) {
          docMap = Map<String, dynamic>.from(rawData);
        } else if (rawData is List &&
            rawData.isNotEmpty &&
            rawData.first is Map) {
          docMap = Map<String, dynamic>.from(rawData.first);
        }

        if (docMap != null) {
          final doc = ComplianceDocumentModel.fromJson(docMap);
          _applyDocState(documentType, doc);
        }

        final msg = response.data?['message'] ??
            (docId != null && docId.isNotEmpty
                ? '$title updated successfully.'
                : '$title uploaded successfully.');
        Helpers.showCustomSnackBar(msg, isError: false);
      } else {
        final msg = response.data?['message'] ?? 'Failed to save $title.';
        Helpers.showCustomSnackBar(msg, isError: true);
      }
    } catch (e) {
      debugPrint("Error saving $title: $e");
      Helpers.showCustomSnackBar(
        'Something went wrong saving $title.',
        isError: true,
      );
    } finally {
      isUpdatingRx.value = false;
    }
  }

  // ─── Helper Mapping Functions ──────────────────────────────────────────────

  String _getTitle(String type) => type == 'DRIVING_LICENSE'
      ? "Driving License"
      : type == 'HACK_LICENSE'
          ? "Hack License"
          : "Local Permit";

  RxnString _getDocIdRx(String type) => type == 'DRIVING_LICENSE'
      ? drivingLicenseId
      : type == 'HACK_LICENSE'
          ? hackLicenseId
          : localPermitId;

  RxnString _getStatusRx(String type) => type == 'DRIVING_LICENSE'
      ? drivingLicenseStatus
      : type == 'HACK_LICENSE'
          ? hackLicenseStatus
          : localPermitStatus;

  RxnString _getUrlRx(String type) => type == 'DRIVING_LICENSE'
      ? drivingLicenseUrl
      : type == 'HACK_LICENSE'
          ? hackLicenseUrl
          : localPermitUrl;

  Rx<File?> _getFileRx(String type) => type == 'DRIVING_LICENSE'
      ? drivingLicenseFile
      : type == 'HACK_LICENSE'
          ? hackLicenseFile
          : localPermitFile;

  TextEditingController _getExpireController(String type) =>
      type == 'DRIVING_LICENSE'
          ? drivingLicenseExpireController
          : type == 'HACK_LICENSE'
              ? hackLicenseExpireController
              : localPermitExpireController;

  RxString getExpiryRx(String type) => type.toUpperCase() == 'DRIVING_LICENSE'
      ? drivingLicenseExpiry
      : type.toUpperCase() == 'HACK_LICENSE'
          ? hackLicenseExpiry
          : localPermitExpiry;

  RxBool _getIsUpdatingRx(String type) => type == 'DRIVING_LICENSE'
      ? isUpdatingDrivingLicense
      : type == 'HACK_LICENSE'
          ? isUpdatingHackLicense
          : isUpdatingLocalPermit;

  void _applyDocState(String documentType, ComplianceDocumentModel doc) {
    final type = documentType.toUpperCase();
    _getDocIdRx(type).value = doc.id;
    _getStatusRx(type).value = doc.status;
    if (doc.fullFileUrl != null && doc.fullFileUrl!.isNotEmpty) {
      _getUrlRx(type).value = doc.fullFileUrl;
    }
    if (doc.formattedExpiryDate.isNotEmpty) {
      _getExpireController(type).text = doc.formattedExpiryDate;
      getExpiryRx(type).value = doc.formattedExpiryDate;
    }
  }

  // ─── Date Picker & Media Picking ────────────────────────────────────────────

  Future<void> selectDate(
    BuildContext context,
    TextEditingController controller, {
    RxString? expiryRx,
    String? documentType,
  }) async {
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
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF1E2939),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      controller.text = formatted;
      if (expiryRx != null) {
        expiryRx.value = formatted;
      } else if (documentType != null) {
        getExpiryRx(documentType).value = formatted;
      }
      update();
    }
  }

  bool _isPicking = false;

  Future<void> _processPickedFile(File file, Rx<File?> target) async {
    final path = file.path.toLowerCase();
    final isImage = !path.endsWith('.pdf');
    final processed = isImage ? await Helpers.compressImage(file) : file;
    final fileSize = await processed.length();

    if (fileSize > 1024 * 1024) {
      Helpers.showCustomSnackBar(
        'Maximum file size allowed is 1MB',
        isError: true,
      );
      return;
    }
    target.value = processed;
  }

  Future<void> pickFromCamera(Rx<File?> target) async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        await _processPickedFile(File(image.path), target);
      }
    } catch (e) {
      Helpers.error('Error picking from camera: $e');
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
        await _processPickedFile(file, target);
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
        await _processPickedFile(file, target);
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

  void previewImage(
    BuildContext context,
    Rx<File?> fileRx,
    RxnString urlRx, {
    String title = "Document Preview",
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

  @override
  void onClose() {
    drivingLicenseExpireController.dispose();
    hackLicenseExpireController.dispose();
    localPermitExpireController.dispose();
    super.onClose();
  }
}
