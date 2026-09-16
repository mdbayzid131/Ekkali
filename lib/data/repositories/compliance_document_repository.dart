import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class ComplianceDocumentRepository {
  final ApiClient apiClient;

  ComplianceDocumentRepository({required this.apiClient});

  /// 1. GET /api/v1/documents/licenses
  /// Retrieves compliance license documents (DRIVING_LICENSE, HACK_LICENSE, LOCAL_PERMIT)
  Future<Response<dynamic>> getComplianceDocuments() async {
    return await apiClient.getData('${ApiConstants.documents}/licenses');
  }

  /// 2. PATCH /api/v1/documents/:id
  /// Updates document expiry date (JSON) and/or attached file (Multipart FormData)
  Future<Response<dynamic>> updateDocument({
    required String documentId,
    String? expiryDate,
    File? file,
  }) async {
    if (file != null) {
      final formData = FormData();
      if (expiryDate != null && expiryDate.trim().isNotEmpty) {
        final formattedDate = _formatDateToIso(expiryDate);
        formData.fields.add(MapEntry('expiryDate', formattedDate));
      }
      formData.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(file.path),
        ),
      );
      return await apiClient.patchData(
        '${ApiConstants.documents}/$documentId',
        formData,
      );
    } else {
      final String formattedDate =
          expiryDate != null ? _formatDateToIso(expiryDate) : '';
      return await apiClient.patchData(
        '${ApiConstants.documents}/$documentId',
        {
          if (formattedDate.isNotEmpty) "expiryDate": formattedDate,
        },
      );
    }
  }

  /// 3. POST /api/v1/documents
  /// Uploads a new document when docId does not exist yet (matches signup upload endpoint)
  Future<Response<dynamic>> uploadDocument({
    required String documentType,
    required File file,
    String? expiryDate,
  }) async {
    final formData = FormData();

    final Map<String, dynamic> docMap = {"documentType": documentType};
    if (expiryDate != null && expiryDate.trim().isNotEmpty) {
      final formattedDate = _formatDateToIso(expiryDate);
      if (formattedDate.isNotEmpty) {
        docMap["expiryDate"] = formattedDate;
      }
    }

    formData.fields.add(MapEntry('data', jsonEncode(docMap)));
    formData.files.add(
      MapEntry('file', await MultipartFile.fromFile(file.path)),
    );

    return await apiClient.postData(ApiConstants.documents, formData);
  }

  String _formatDateToIso(String dateStr) {
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return trimmed;
    try {
      final parsed = DateTime.parse(trimmed);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat('dd MMMM yyyy').parse(trimmed);
        return DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {
        return trimmed;
      }
    }
  }
}
