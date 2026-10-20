import 'chat_model.dart';

class CommunityRoom {
  final String? _id;
  final String name;
  final String serviceArea;
  final String status;
  final int totalMembers;
  final String? lastMessage;
  final String? lastMessageAt;
  int unreadCount;
  bool isRead;

  String get id => (_id != null && _id.isNotEmpty)
      ? _id
      : (serviceArea.isNotEmpty ? serviceArea : 'global');

  CommunityRoom({
    String? id,
    required this.name,
    this.serviceArea = '',
    this.status = 'ACTIVE',
    this.totalMembers = 0,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isRead = true,
  }) : _id = id;

  factory CommunityRoom.fromJson(Map<String, dynamic> json) {
    final unread = json['unreadCount'] is int
        ? json['unreadCount'] as int
        : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0;
    final isReadVal = json['isRead'] is bool
        ? json['isRead'] as bool
        : (unread == 0);

    String? lastMsg;
    String? lastMsgAt;
    if (json['lastMessage'] != null) {
      if (json['lastMessage'] is Map) {
        lastMsg =
            json['lastMessage']['text']?.toString() ??
            json['lastMessage']['message']?.toString() ??
            json['lastMessage']['content']?.toString();
        if ((lastMsg == null || lastMsg.trim().isEmpty) &&
            json['lastMessage']['attachments'] is List &&
            (json['lastMessage']['attachments'] as List).isNotEmpty) {
          lastMsg = 'Attachment';
        }
        lastMsgAt = json['lastMessage']['createdAt']?.toString();
      } else {
        lastMsg = json['lastMessage']?.toString();
      }
    }

    if (lastMsg == null || lastMsg.trim().isEmpty) {
      if (json['attachments'] is List &&
          (json['attachments'] as List).isNotEmpty) {
        lastMsg = 'Attachment';
      }
    }

    lastMsgAt ??= json['lastMessageAt']?.toString();

    return CommunityRoom(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      serviceArea: json['serviceArea'] is Map
          ? (json['serviceArea']['areaName']?.toString() ??
                json['serviceArea']['name']?.toString() ??
                '')
          : (json['serviceArea']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'ACTIVE',
      totalMembers: json['totalMembers'] is int
          ? json['totalMembers'] as int
          : int.tryParse(json['totalMembers']?.toString() ?? '0') ?? 0,
      lastMessage: lastMsg,
      lastMessageAt: lastMsgAt,
      unreadCount: unread,
      isRead: isReadVal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityRoom &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          serviceArea == other.serviceArea &&
          status == other.status &&
          totalMembers == other.totalMembers &&
          lastMessage == other.lastMessage &&
          lastMessageAt == other.lastMessageAt &&
          unreadCount == other.unreadCount &&
          isRead == other.isRead;

  @override
  int get hashCode => id.hashCode;

  CommunityRoom copyWith({
    String? lastMessage,
    String? lastMessageAt,
    int? unreadCount,
    bool? isRead,
  }) => CommunityRoom(
    id: id,
    name: name,
    serviceArea: serviceArea,
    status: status,
    totalMembers: totalMembers,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    isRead: isRead ?? this.isRead,
  );
}

class CommunityMessage {
  /// Both socket streams use this normalizer. Preserve the room on envelopes.
  static Map<String, dynamic>? eventPayload(dynamic event) {
    if (event is! Map) return null;
    var payload = Map<String, dynamic>.from(event);
    for (var depth = 0; depth < 4; depth++) {
      final nested = payload['data'] is Map
          ? payload['data']
          : (payload['message'] is Map ? payload['message'] : null);
      if (nested is! Map) break;
      payload.remove('data');
      if (payload['message'] is Map) payload.remove('message');
      payload = {...payload, ...Map<String, dynamic>.from(nested)};
    }
    final chat = payload['chatId'] ?? payload['chat'] ?? payload['groupId'];
    payload['chatId'] = chat is Map
        ? (chat['_id'] ?? chat['id'])?.toString() ?? ''
        : chat?.toString() ?? '';
    return payload;
  }

  final String id;
  final String? chatId;
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
    this.chatId,
    this.serviceArea = '',
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

    final String parsedChatId =
        json['chatId']?.toString() ??
        (json['chat'] is Map
            ? json['chat']['_id']?.toString() ?? ''
            : json['chat']?.toString() ?? '');
    final String parsedServiceArea = json['serviceArea'] is Map
        ? (json['serviceArea']['areaName']?.toString() ??
              json['serviceArea']['name']?.toString() ??
              '')
        : (json['serviceArea']?.toString() ?? '');

    return CommunityMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      chatId: parsedChatId.isNotEmpty ? parsedChatId : null,
      serviceArea: parsedServiceArea,
      sender: senderObj,
      text:
          json['text']?.toString() ??
          json['message']?.toString() ??
          json['content']?.toString() ??
          '',
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
