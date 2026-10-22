import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class ComplianceDocumentRepository {
  final ApiClient apiClient;
  final Dio _mediaClient;

  ComplianceDocumentRepository({required this.apiClient, Dio? mediaClient})
    : _mediaClient =
          mediaClient ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  /// 1. GET /api/v1/documents/licenses
  /// Retrieves compliance license documents (DRIVING_LICENSE, HACK_LICENSE, LOCAL_PERMIT)
  Future<Response<dynamic>> getComplianceDocuments() async {
    return await apiClient.getData('${ApiConstants.documents}/licenses');
  }

  /// 2. PATCH /api/v1/documents/:id
  /// Always submits a file with the expiry, reusing existing media if needed.
  Future<Response<dynamic>> updateDocument({
    required String documentId,
    String? expiryDate,
    File? file,
    String? existingFileUrl,
  }) async {
    final MultipartFile attachment;
    if (file != null) {
      attachment = await MultipartFile.fromFile(file.path);
    } else {
      final uri = Uri.tryParse(existingFileUrl?.trim() ?? '');
      if (uri == null ||
          !const ['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty) {
        throw ArgumentError(
          'An existing or newly selected document file is required.',
        );
      }
      // Public document media uses a separate client so API credentials are
      // never forwarded to a storage/CDN host.
      final response = await _mediaClient.get<List<int>>(
        uri.toString(),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('The existing document file could not be loaded.');
      }
      attachment = MultipartFile.fromBytes(
        bytes,
        filename: uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'document',
      );
    }
    final formData = FormData();
    if (expiryDate != null && expiryDate.trim().isNotEmpty) {
      final formattedDate = _formatDateToIso(expiryDate);
      formData.fields.add(MapEntry('expiryDate', formattedDate));
    }
    formData.files.add(MapEntry('file', attachment));
    return await apiClient.patchData(
      '${ApiConstants.documents}/$documentId',
      formData,
    );
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
