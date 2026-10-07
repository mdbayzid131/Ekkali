import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/services/badge_service.dart';
import 'package:moeb_26/data/repositories/notifications_repository.dart';

class NotificationsService extends GetxService {
  late NotificationsRepo _notificationsRepo;

  @override
  void onInit() {
    super.onInit();
    _notificationsRepo = NotificationsRepo(apiClient: Get.find<ApiClient>());
  }

  Future<int> syncUnreadBadge() async {
    try {
      final response = await getMyNotifications();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic resData = response.data?['data'];
        List<dynamic>? dataList;
        if (resData is List) {
          dataList = resData;
        } else if (resData is Map && resData['notifications'] is List) {
          dataList = resData['notifications'];
        }

        if (dataList != null) {
          final unreadCount = dataList
              .whereType<Map<String, dynamic>>()
              .where((json) => json['isRead'] == false || json['read'] == false)
              .length;
          await BadgeService.updateBadgeCount(unreadCount);
          return unreadCount;
        }
      }
    } catch (_) {}
    return 0;
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
