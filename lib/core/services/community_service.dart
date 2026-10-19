import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/data/repositories/community_repository.dart';

class CommunityService extends GetxService {
  late CommunityRepo _communityRepo;

  @override
  void onInit() {
    super.onInit();
    _communityRepo = CommunityRepo(apiClient: Get.find());
  }

  /// Get all admin-created chat groups (channels)
  Future<Response> getChatGroups() async {
    try {
      return await _communityRepo.getChatGroups();
    } catch (e) {
      rethrow;
    }
  }

  /// Get messages for a specific group by chatId
  Future<Response> getGroupMessages(
    String chatId, {
    int? page,
    int limit = 50,
    String? cursor,
  }) async {
    try {
      return await _communityRepo.getGroupMessages(
        chatId,
        page: page,
        limit: limit,
        cursor: cursor,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Send message to a specific group by chatId
  Future<Response> sendGroupMessage(
    String chatId, {
    required String text,
    List<File>? attachments,
    String? replyTo,
  }) async {
    try {
      return await _communityRepo.sendGroupMessage(
        chatId,
        text: text,
        attachments: attachments,
        replyTo: replyTo,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getCommunityRoom({String? serviceArea}) async {
    try {
      return await _communityRepo.getCommunityRoom(serviceArea: serviceArea);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getCommunityMessages({
    int? page,
    int limit = 40,
    String? serviceArea,
    String? cursor,
  }) async {
    try {
      return await _communityRepo.getCommunityMessages(
        page: page,
        limit: limit,
        serviceArea: serviceArea,
        cursor: cursor,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> sendCommunityMessage({
    required String text,
    List<File>? attachments,
    String? replyTo,
    String? serviceArea,
  }) async {
    try {
      return await _communityRepo.sendCommunityMessage(
        text: text,
        attachments: attachments,
        replyTo: replyTo,
        serviceArea: serviceArea,
      );
    } catch (e) {
      rethrow;
    }
  }
}
