import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/data/repositories/notifications_repository.dart';

class NotificationsService extends GetxService {
  late NotificationsRepo _notificationsRepo;

  @override
  void onInit() {
    super.onInit();
    _notificationsRepo = NotificationsRepo(apiClient: Get.find<ApiClient>());
  }

  Future<Response> getMyNotifications() async {
    try {
      return await _notificationsRepo.getMyNotifications();
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> markAllAsRead() async {
    try {
      return await _notificationsRepo.markAllAsRead();
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> markAsRead(String notificationId) async {
    try {
      return await _notificationsRepo.markAsRead(notificationId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> deleteNotification(String notificationId) async {
    try {
      return await _notificationsRepo.deleteNotification(notificationId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> registerDeviceToken(String token) async {
    try {
      return await _notificationsRepo.registerDeviceToken(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> unregisterDeviceToken(String token) async {
    try {
      return await _notificationsRepo.unregisterDeviceToken(token);
    } catch (e) {
      rethrow;
    }
  }
}
