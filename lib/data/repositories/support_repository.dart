import 'dart:io';
import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class SupportRepo {
  final ApiClient apiClient;
  SupportRepo({required this.apiClient});

  /// ===================== GET MY TICKETS =====================
  Future<Response> getMyTickets() async {
    return await apiClient.getData(ApiConstants.myTickets);
  }

  /// ===================== CREATE SUPPORT TICKET =====================
  Future<Response> createSupport({
    required String subject,
    required String message,
    List<File>? attachments,
  }) async {
    if (attachments != null && attachments.isNotEmpty) {
      final multipartList = attachments
          .map((file) => MultipartBody("attachments", file))
          .toList();
      return await apiClient.postMultipartData(ApiConstants.createSupport, {
        "subject": subject,
        "message": message,
      }, multipartBody: multipartList);
    } else {
      return await apiClient.postData(ApiConstants.createSupport, {
        "subject": subject,
        "message": message,
      });
    }
  }

  /// ===================== GET SUPPORT TICKET DETAILS & MESSAGES =====================
  Future<Response> getSupportDetails(String ticketId) async {
    return await apiClient.getData('${ApiConstants.supports}/$ticketId');
  }

  /// ===================== GET MESSAGES =====================
  Future<Response> getMessages(
    String chatId, {
    int page = 1,
    int limit = 20,
  }) async {
    return await getSupportDetails(chatId);
  }

  /// ===================== SEND REPLY MESSAGE =====================
  /// POST /api/v1/supports/:ticketId/messages
  /// Content-Type: multipart/form-data
  /// Body: message (Required), attachments (Optional)
  Future<Response> sendMessage(
    String ticketId,
    String message, {
    List<File>? attachments,
  }) async {
    final uri = '${ApiConstants.supports}/$ticketId/messages';
    if (attachments != null && attachments.isNotEmpty) {
      final multipartList = attachments
          .map((file) => MultipartBody("attachments", file))
          .toList();
      return await apiClient.postMultipartData(
        uri,
        {"message": message},
        multipartBody: multipartList,
      );
    } else {
      final formData = FormData.fromMap({"message": message});
      return await apiClient.postData(
        uri,
        formData,
        extraHeaders: {'Content-Type': 'multipart/form-data'},
      );
    }
  }
}
