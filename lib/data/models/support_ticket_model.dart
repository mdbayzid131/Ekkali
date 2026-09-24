class SupportTicket {
  final String id;
  final String subject;
  final String user;
  final String status;
  final List<SupportMessage> messages;
  final String createdAt;
  final String updatedAt;
  final SupportChat? chat;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.user,
    this.status = 'PENDING',
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.chat,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['_id'] ?? json['id'] ?? '',
      subject: json['subject'] ?? '',
      user: json['user'] is Map
          ? (json['user']['_id'] ?? json['user']['id'] ?? '')
          : (json['user']?.toString() ?? ''),
      status: json['status'] ?? 'PENDING',
      messages:
          (json['messages'] as List?)
              ?.map((i) => SupportMessage.fromJson(i))
              .toList() ??
          [],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      chat: json['chat'] != null ? SupportChat.fromJson(json['chat']) : null,
    );
  }
}

class SupportMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final List<String> attachments;
  final String createdAt;

  SupportMessage({
    required this.id,
    required this.senderId,
    this.senderName = '',
    this.senderRole = '',
    required this.message,
    this.attachments = const [],
    required this.createdAt,
  });

  String get sender => senderName.isNotEmpty ? senderName : senderId;
  String get text => message;

  bool isSentBy(String? currentUserId) {
    if (currentUserId == null || currentUserId.trim().isEmpty) return false;
    return senderId.trim() == currentUserId.trim();
  }

  String get time {
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final hour = dateTime.hour > 12
          ? dateTime.hour - 12
          : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } catch (_) {
      return 'Now';
    }
  }

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    String senderId = '';
    String senderName = '';
    String senderRole = '';

    final dynamic senderData = json['sender'] ?? json['user'];
    if (senderData is Map) {
      senderId =
          senderData['_id']?.toString() ?? senderData['id']?.toString() ?? '';
      senderName = senderData['name']?.toString() ??
          senderData['fullName']?.toString() ??
          '';
      senderRole = senderData['role']?.toString() ?? '';
    } else if (senderData != null) {
      senderId = senderData.toString();
    }

    if (senderId.isEmpty) {
      senderId = json['senderId']?.toString() ?? json['userId']?.toString() ?? '';
    }
    if (senderName.isEmpty) {
      senderName = json['senderName']?.toString() ?? '';
    }
    if (senderRole.isEmpty) {
      senderRole = json['role']?.toString() ?? json['senderRole']?.toString() ?? '';
    }

    return SupportMessage(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      message: json['message']?.toString() ?? json['text']?.toString() ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class SupportChat {
  final String id;
  final String supportId;

  SupportChat({required this.id, required this.supportId});

  factory SupportChat.fromJson(Map<String, dynamic> json) {
    return SupportChat(
      id: json['_id'] ?? json['id'] ?? '',
      supportId: json['supportId'] ?? '',
    );
  }
}
