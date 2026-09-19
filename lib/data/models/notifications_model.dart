import 'package:moeb_26/config/constants/icon_paths.dart';

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String icon;

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.icon,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    String type = json['type']?.toString() ??
        json['notificationType']?.toString() ??
        'GENERAL';
    String iconPath = AppIcons.job_icon;

    if (type.toUpperCase().contains('JOB') ||
        type.toUpperCase().contains('RIDE') ||
        type.toUpperCase().contains('TASK')) {
      iconPath = AppIcons.job_icon;
    } else if (type.toUpperCase().contains('MESSAGE') ||
        type.toUpperCase().contains('CHAT')) {
      iconPath = AppIcons.message_icon;
    } else if (type.toUpperCase().contains('REMINDER') ||
        type.toUpperCase().contains('OFFER') ||
        type.toUpperCase().contains('DEAL')) {
      iconPath = AppIcons.deals_icon;
    } else {
      iconPath = AppIcons.job_icon;
    }

    DateTime parsedDate = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        parsedDate = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    return NotificationItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['heading']?.toString() ??
          'Notification',
      subtitle: json['message']?.toString() ??
          json['text']?.toString() ??
          json['body']?.toString() ??
          json['subtitle']?.toString() ??
          '',
      type: type,
      isRead: json['isRead'] == true ||
          json['read'] == true ||
          json['status']?.toString().toUpperCase() == 'READ',
      createdAt: parsedDate,
      icon: iconPath,
    );
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
