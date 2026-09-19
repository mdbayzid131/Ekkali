import 'chat_model.dart';

class CommunityRoom {
  final String name;
  final String serviceArea;
  final int totalMembers;
  final String? lastMessage;
  final String? lastMessageAt;
  int unreadCount;
  bool isRead;

  CommunityRoom({
    required this.name,
    required this.serviceArea,
    this.totalMembers = 0,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isRead = true,
  });

  factory CommunityRoom.fromJson(Map<String, dynamic> json) {
    final unread = json['unreadCount'] is int
        ? json['unreadCount'] as int
        : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0;
    final isReadVal = json['isRead'] is bool
        ? json['isRead'] as bool
        : (unread == 0);

    return CommunityRoom(
      name: json['name'] ?? '',
      serviceArea: json['serviceArea'] is Map
          ? (json['serviceArea']['areaName']?.toString() ??
              json['serviceArea']['name']?.toString() ??
              '')
          : (json['serviceArea']?.toString() ?? ''),
      totalMembers: json['totalMembers'] is int
          ? json['totalMembers'] as int
          : int.tryParse(json['totalMembers']?.toString() ?? '0') ?? 0,
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'],
      unreadCount: unread,
      isRead: isReadVal,
    );
  }
}

class CommunityMessage {
  final String id;
  final String serviceArea;
  final ChatParticipant sender;
  final String text;
  final List<String> attachments;
  final String? replyTo;
  final CommunityMessage? replyToMessage;
  final String createdAt;
  final String updatedAt;

  CommunityMessage({
    required this.id,
    required this.serviceArea,
    required this.sender,
    required this.text,
    required this.attachments,
    this.replyTo,
    this.replyToMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    ChatParticipant senderObj;
    final dynamic senderData = json['sender'];
    if (senderData is Map<String, dynamic>) {
      senderObj = ChatParticipant.fromJson(senderData);
    } else if (senderData is String) {
      senderObj = ChatParticipant(id: senderData, name: '');
    } else {
      senderObj = ChatParticipant(id: '', name: '');
    }

    String? replyToId;
    CommunityMessage? populatedReplyTo;
    final dynamic replyToData = json['replyTo'];
    if (replyToData is Map<String, dynamic>) {
      populatedReplyTo = CommunityMessage.fromJson(replyToData);
      replyToId = populatedReplyTo.id;
    } else if (replyToData is String) {
      replyToId = replyToData;
    }

    return CommunityMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      serviceArea: json['serviceArea'] is Map
          ? (json['serviceArea']['areaName']?.toString() ??
              json['serviceArea']['name']?.toString() ??
              '')
          : (json['serviceArea']?.toString() ?? ''),
      sender: senderObj,
      text: json['text']?.toString() ?? '',
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : [],
      replyTo: replyToId,
      replyToMessage: populatedReplyTo,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  String get time {
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } catch (_) {
      return 'Now';
    }
  }
}
