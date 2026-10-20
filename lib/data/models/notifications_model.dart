import 'package:moeb_26/config/constants/icon_paths.dart';
import 'notification_payload.dart';

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
  final bool isBroadcast;
  final String? imageUrl;

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
    this.isBroadcast = false,
    this.imageUrl,
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
    bool? isBroadcast,
    String? imageUrl,
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
      isBroadcast: isBroadcast ?? this.isBroadcast,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    String type =
        json['type']?.toString() ??
        json['notificationType']?.toString() ??
        'GENERAL';
    String iconPath = AppIcons.job_icon;

    Map<String, dynamic>? rawData;
    if (json['data'] is Map<String, dynamic>) {
      rawData = json['data'] as Map<String, dynamic>;
    } else if (json['payload'] is Map<String, dynamic>) {
      rawData = json['payload'] as Map<String, dynamic>;
    }

    final String? resourceType =
        json['resourceType']?.toString() ??
        rawData?['resourceType']?.toString();
    final String? resourceId =
        json['resourceId']?.toString() ??
        rawData?['resourceId']?.toString() ??
        json['referenceId']?.toString() ??
        rawData?['referenceId']?.toString();

    final String titleUpper =
        (json['title']?.toString() ?? json['heading']?.toString() ?? '')
            .toUpperCase();
    final String textUpper =
        (json['text']?.toString() ??
                json['message']?.toString() ??
                json['body']?.toString() ??
                '')
            .toUpperCase();
    final String resUpper = (resourceType ?? '').toUpperCase();
    final String typeUpper = type.toUpperCase();

    if (resUpper == 'DOCUMENT' ||
        typeUpper.contains('DOCUMENT') ||
        titleUpper.contains('DOCUMENT') ||
        textUpper.contains('DOCUMENT') ||
        titleUpper.contains('LICENSE') ||
        textUpper.contains('LICENSE') ||
        titleUpper.contains('PERMIT') ||
        textUpper.contains('PERMIT')) {
      iconPath = AppIcons.contact_icon;
    } else if (resUpper == 'VEHICLE' ||
        typeUpper.contains('VEHICLE') ||
        titleUpper.contains('VEHICLE') ||
        textUpper.contains('VEHICLE')) {
      iconPath = AppIcons.vechile_car_icon;
    } else if (typeUpper.contains('JOB') ||
        typeUpper.contains('RIDE') ||
        typeUpper.contains('TASK') ||
        typeUpper.contains('CHAUFFEUR') ||
        resUpper == 'JOB') {
      iconPath = AppIcons.job_icon;
    } else if (resUpper == 'SUPPORT_TICKET' || typeUpper.contains('SUPPORT')) {
      iconPath = AppIcons.message_icon;
    } else if (typeUpper.contains('MESSAGE') || typeUpper.contains('CHAT')) {
      iconPath = AppIcons.message_icon;
    } else if (typeUpper.contains('PAYMENT') || typeUpper.contains('INVOICE')) {
      iconPath = AppIcons.deals_icon;
    } else if (typeUpper.contains('REMINDER') ||
        typeUpper.contains('OFFER') ||
        typeUpper.contains('DEAL')) {
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

    final dynamic jobObj = (json['job'] is Map)
        ? json['job']
        : (rawData != null && rawData['job'] is Map ? rawData['job'] : null);
    final dynamic chatObj = (json['chat'] is Map)
        ? json['chat']
        : (rawData != null && rawData['chat'] is Map ? rawData['chat'] : null);

    String? parsedJobId =
        json['jobId']?.toString() ??
        rawData?['jobId']?.toString() ??
        json['rideId']?.toString() ??
        rawData?['rideId']?.toString() ??
        (resUpper == 'JOB' ? resourceId : null);

    if (parsedJobId == null && jobObj is Map) {
      parsedJobId = jobObj['_id']?.toString() ?? jobObj['id']?.toString();
    }

    String? parsedChatId =
        json['chatId']?.toString() ?? rawData?['chatId']?.toString();

    if (parsedChatId == null && chatObj is Map) {
      parsedChatId = chatObj['_id']?.toString() ?? chatObj['id']?.toString();
    }

    // Preserve full payload so navigation routes never miss resourceType or referenceId
    final Map<String, dynamic> combinedData = {...json, ...?rawData};
    final broadcast = NotificationPayload.isBroadcast(combinedData, type: type);

    return NotificationItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title:
          (broadcast
              ? NotificationPayload.text(combinedData, ['title', 'heading'])
              : null) ??
          json['title']?.toString() ??
          json['heading']?.toString() ??
          'Notification',
      subtitle:
          (broadcast
              ? NotificationPayload.text(combinedData, [
                  'description',
                  'text',
                  'body',
                  'message',
                  'subtitle',
                ])
              : null) ??
          json['message']?.toString() ??
          json['text']?.toString() ??
          json['body']?.toString() ??
          json['subtitle']?.toString() ??
          '',
      type: type,
      isRead:
          json['isRead'] == true ||
          json['read'] == true ||
          json['status']?.toString().toUpperCase() == 'READ',
      createdAt: parsedDate,
      icon: iconPath,
      jobId: parsedJobId,
      chatId: parsedChatId,
      data: combinedData,
      isBroadcast: broadcast,
      imageUrl: broadcast ? NotificationPayload.imageUrl(combinedData) : null,
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
