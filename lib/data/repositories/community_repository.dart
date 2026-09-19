import 'dart:io';
import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class CommunityRepo {
  final ApiClient apiClient;
  CommunityRepo({required this.apiClient});

  Future<Response> getCommunityRoom({String? serviceArea}) async {
    final query = <String, dynamic>{};
    if (serviceArea != null && serviceArea.isNotEmpty) {
      query['serviceArea'] = serviceArea;
    }
    return await apiClient.getData(
      ApiConstants.communityRoom,
      query: query.isNotEmpty ? query : null,
    );
  }

  Future<Response> getCommunityMessages({
    int? page,
    int limit = 40,
    String? serviceArea,
    String? cursor,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (page != null) query['page'] = page;
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    if (serviceArea != null && serviceArea.isNotEmpty) {
      query['serviceArea'] = serviceArea;
    }
    return await apiClient.getData(ApiConstants.communityMessages, query: query);
  }

  Future<Response> sendCommunityMessage({
    required String text,
    List<File>? attachments,
    String? replyTo,
    String? serviceArea,
  }) async {
    final formData = FormData();
    if (text.isNotEmpty) {
      formData.fields.add(MapEntry('text', text));
    }
    if (serviceArea != null && serviceArea.isNotEmpty) {
      formData.fields.add(MapEntry('serviceArea', serviceArea));
    }
    if (replyTo != null && replyTo.isNotEmpty) {
      formData.fields.add(MapEntry('replyTo', replyTo));
    }

    if (attachments != null && attachments.isNotEmpty) {
      for (var file in attachments) {
        formData.files.add(
          MapEntry(
            'attachments',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }
    }

    return await apiClient.postData(ApiConstants.communityMessages, formData);
  }
}
