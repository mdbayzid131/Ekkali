import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/data/repositories/support_repository.dart';

class SupportService extends GetxService {
  late SupportRepo _supportRepo;

  @override
  void onInit() {
    super.onInit();
    _supportRepo = SupportRepo(apiClient: Get.find());
  }

  Future<Response> getMyTickets() async {
    try {
      return await _supportRepo.getMyTickets();
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> createSupport({
    required String subject,
    required String message,
    List<File>? attachments,
  }) async {
    try {
      return await _supportRepo.createSupport(
        subject: subject,
        message: message,
        attachments: attachments,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getSupportDetails(String ticketId) async {
    try {
      return await _supportRepo.getSupportDetails(ticketId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getMessages(String chatId) async {
    try {
      return await _supportRepo.getMessages(chatId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> sendMessage(
    String ticketId,
    String message, {
    List<File>? attachments,
  }) async {
    try {
      return await _supportRepo.sendMessage(
        ticketId,
        message,
        attachments: attachments,
      );
    } catch (e) {
      rethrow;
    }
  }
}
