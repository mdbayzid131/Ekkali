import 'package:intl/intl.dart';
import 'package:moeb_26/config/constants/api_constants.dart';

class ComplianceDocumentResponse {
  final bool success;
  final String message;
  final List<ComplianceDocumentModel> data;

  ComplianceDocumentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ComplianceDocumentResponse.fromJson(Map<String, dynamic> json) {
    return ComplianceDocumentResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) =>
                  ComplianceDocumentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class ComplianceDocumentModel {
  final String id;
  final String documentType;
  final String? expiryDate;
  final String status;
  final int version;
  final String? scanResult;
  final int scanAttempts;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fileUrl;

  ComplianceDocumentModel({
    required this.id,
    required this.documentType,
    this.expiryDate,
    required this.status,
    this.version = 1,
    this.scanResult,
    this.scanAttempts = 0,
    this.createdAt,
    this.updatedAt,
    this.fileUrl,
  });

  factory ComplianceDocumentModel.fromJson(Map<String, dynamic> json) {
    return ComplianceDocumentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      documentType: json['documentType']?.toString() ?? '',
      expiryDate: json['expiryDate']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      version: json['version'] is int
          ? json['version'] as int
          : (int.tryParse(json['version']?.toString() ?? '1') ?? 1),
      scanResult: json['scanResult']?.toString(),
      scanAttempts: json['scanAttempts'] is int
          ? json['scanAttempts'] as int
          : (int.tryParse(json['scanAttempts']?.toString() ?? '0') ?? 0),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      fileUrl: json['fileUrl']?.toString() ??
          json['storageKey']?.toString() ??
          json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'documentType': documentType,
      'expiryDate': expiryDate,
      'status': status,
      'version': version,
      'scanResult': scanResult,
      'scanAttempts': scanAttempts,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'fileUrl': fileUrl,
    };
  }

  /// Formatted expiry date string (yyyy-MM-dd)
  String get formattedExpiryDate {
    if (expiryDate == null || expiryDate!.isEmpty) return '';
    try {
      final parsed = DateTime.parse(expiryDate!);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return expiryDate!;
    }
  }

  /// Resolves relative URL (e.g. /uploads/...) to a complete accessible URL
  String? get fullFileUrl {
    if (fileUrl == null || fileUrl!.isEmpty) return null;
    if (fileUrl!.startsWith('http://') || fileUrl!.startsWith('https://')) {
      return fileUrl;
    }
    final serverBase = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    final cleanPath = fileUrl!.startsWith('/') ? fileUrl! : '/$fileUrl';
    return '$serverBase$cleanPath';
  }

  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isPending =>
      status.toUpperCase().contains('PENDING') ||
      status.toUpperCase().contains('SCAN');
  bool get isRejected =>
      status.toUpperCase().contains('REJECT') ||
      status.toUpperCase().contains('DECLIN');
}
