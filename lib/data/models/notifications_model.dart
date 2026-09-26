import 'package:moeb_26/config/constants/icon_paths.dart';

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String icon;
  final String? jobId;
  final String? chatId;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.icon,
    this.jobId,
    this.chatId,
    this.data,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? icon,
    String? jobId,
    String? chatId,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
      jobId: jobId ?? this.jobId,
      chatId: chatId ?? this.chatId,
      data: data ?? this.data,
    );
  }

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

    Map<String, dynamic>? rawData;
    if (json['data'] is Map<String, dynamic>) {
      rawData = json['data'] as Map<String, dynamic>;
    } else if (json['payload'] is Map<String, dynamic>) {
      rawData = json['payload'] as Map<String, dynamic>;
    }

    final dynamic jobObj = (json['job'] is Map)
        ? json['job']
        : (rawData != null && rawData['job'] is Map ? rawData['job'] : null);
    final dynamic chatObj = (json['chat'] is Map)
        ? json['chat']
        : (rawData != null && rawData['chat'] is Map ? rawData['chat'] : null);

    String? parsedJobId = json['jobId']?.toString() ??
        rawData?['jobId']?.toString() ??
        rawData?['id']?.toString() ??
        rawData?['_id']?.toString() ??
        json['rideId']?.toString() ??
        rawData?['rideId']?.toString();

    if (parsedJobId == null && jobObj is Map) {
      parsedJobId = jobObj['_id']?.toString() ?? jobObj['id']?.toString();
    }

    String? parsedChatId = json['chatId']?.toString() ??
        rawData?['chatId']?.toString();

    if (parsedChatId == null && chatObj is Map) {
      parsedChatId = chatObj['_id']?.toString() ?? chatObj['id']?.toString();
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
      jobId: parsedJobId,
      chatId: parsedChatId,
      data: rawData ?? (json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null),
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
