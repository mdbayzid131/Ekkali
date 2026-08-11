import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/core/services/notifications_service.dart';
import 'package:moeb_26/data/models/Notifications_Model.dart';

class NotificationController extends GetxController {
  final NotificationsService _notificationsService =
      Get.find<NotificationsService>();

  var notifications = <NotificationItem>[].obs;
  var isLoading = false.obs;

  final RxList<String> mutedIds = <String>[].obs;
  final RxList<String> deletedIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    notifications.assignAll(_getDemoNotifications());
    loadMuteAndDeletedStates();
  }

  Future<void> loadMuteAndDeletedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mutedIds.assignAll(prefs.getStringList('muted_notifications') ?? []);
      deletedIds.assignAll(prefs.getStringList('deleted_notifications') ?? []);
    } catch (e) {
      debugPrint("Error loading mute/delete states: $e");
    }
  }

  bool isMuted(String id) => mutedIds.contains(id);
  bool isDeleted(String id) => deletedIds.contains(id);

  Future<void> toggleMuteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mutedIds.contains(id)) {
        mutedIds.remove(id);
      } else {
        mutedIds.add(id);
      }
      await prefs.setStringList('muted_notifications', mutedIds);
      notifications.refresh();
    } catch (e) {
      debugPrint("Error toggling mute: $e");
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      deletedIds.add(id);
      await prefs.setStringList('deleted_notifications', deletedIds);
      // Remove locally from the active list
      notifications.removeWhere((n) => n.id == id);
      // Call DELETE on API if needed, fallback gracefully
      try {
        await _notificationsService.deleteNotification(id);
      } catch (_) {}
    } catch (e) {
      debugPrint("Error deleting notification: $e");
    }
  }

  // Unread notifications count (excluding muted notifications)
  int get unreadCount =>
      notifications.where((n) => !n.isRead && !isMuted(n.id)).length;

  List<NotificationItem> _getDemoNotifications() {
    final list = [
      NotificationItem(
        id: "demo_1",
        title: "Ride Request Accepted",
        subtitle:
            "Your chauffeur request for trip #TX-8921 has been accepted by John Doe.",
        type: "TASK",
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        icon: AppIcons.job_icon,
      ),
      NotificationItem(
        id: "demo_2",
        title: "Chauffeur on the Way",
        subtitle: "Driver is heading to your pick-up location at 450 Ocean Dr.",
        type: "TASK",
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        icon: AppIcons.job_icon,
      ),
      NotificationItem(
        id: "demo_3",
        title: "New Message from Driver",
        subtitle:
            "Hello! I have arrived at the lobby. Let me know when you are ready.",
        type: "MESSAGE",
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        icon: AppIcons.message_icon,
      ),
      NotificationItem(
        id: "demo_4",
        title: "Support Ticket Resolved",
        subtitle:
            "Support ticket #ST-3490 regarding payment query has been resolved.",
        type: "MESSAGE",
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        icon: AppIcons.message_icon,
      ),
      NotificationItem(
        id: "demo_5",
        title: "Upcoming Ride Reminder",
        subtitle:
            "Your scheduled ride to Miami International Airport starts in 2 hours.",
        type: "REMINDER",
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        icon: AppIcons.deals_icon,
      ),
      NotificationItem(
        id: "demo_6",
        title: "Weekend Discount Offer",
        subtitle:
            "Book any premium SUV this weekend and get a flat 15% off. Use code: WEEKEND15",
        type: "REMINDER",
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        icon: AppIcons.deals_icon,
      ),
      NotificationItem(
        id: "demo_7",
        title: "New Invoice Available",
        subtitle: "Invoice #INV-8729 for your recent ride has been generated.",
        type: "GENERAL",
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        icon: AppIcons.job_icon,
      ),
      NotificationItem(
        id: "demo_8",
        title: "Profile Verified Successfully",
        subtitle:
            "Your profile documents have been verified. You can now request trips.",
        type: "GENERAL",
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        icon: AppIcons.job_icon,
      ),
    ];
    // Filter out deleted ones
    return list.where((n) => !deletedIds.contains(n.id)).toList();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final response = await _notificationsService.getMyNotifications();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic>? data = response.data['data'];
        if (data != null) {
          final items = data
              .map((json) => NotificationItem.fromJson(json))
              .where((n) => !deletedIds.contains(n.id))
              .toList();
          notifications.assignAll(items);
        }
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      isLoading.value = false;
      // Always add manually defined demo notifications if they are not deleted
      final demoList = _getDemoNotifications();
      final currentList = notifications.toList();
      for (var demo in demoList) {
        if (!currentList.any((n) => n.id == demo.id)) {
          currentList.add(demo);
        }
      }
      notifications.assignAll(currentList);
    }
  }

  // সব notifications clear করার method (Mark all as read)
  Future<void> markAllAsRead() async {
    try {
      final response = await _notificationsService.markAllAsRead();
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local list directly for instant UI feedback
        for (var i = 0; i < notifications.length; i++) {
          notifications[i] = NotificationItem(
            id: notifications[i].id,
            title: notifications[i].title,
            subtitle: notifications[i].subtitle,
            type: notifications[i].type,
            isRead: true,
            createdAt: notifications[i].createdAt,
            icon: notifications[i].icon,
          );
        }
        notifications.refresh();
      }
    } catch (e) {
      debugPrint("Error marking all as read: $e");
    }
  }

  // Single notification mark as read করার method
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _notificationsService.markAsRead(notificationId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Find and update locally
        int index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = NotificationItem(
            id: notifications[index].id,
            title: notifications[index].title,
            subtitle: notifications[index].subtitle,
            type: notifications[index].type,
            isRead: true,
            createdAt: notifications[index].createdAt,
            icon: notifications[index].icon,
          );
          notifications.refresh();
        }
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  // Single notification remove করার method (If API supports delete)
  void removeNotification(int index) {
    // Currently using mock remove if API not available
    notifications.removeAt(index);
  }
}
