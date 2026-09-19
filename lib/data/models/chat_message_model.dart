import 'package:moeb_26/data/models/chat_model.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final ChatParticipant? sender;
  final String? senderId; // fallback when sender is just an ID string
  final String text;
  final List<String> attachments;
  final String? replyTo;
  final ChatMessage? replyToMessage;
  final String createdAt;
  final String updatedAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    this.sender,
    this.senderId,
    required this.text,
    this.attachments = const [],
    this.replyTo,
    this.replyToMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    ChatParticipant? senderObj;
    String? senderIdStr;

    final dynamic senderData = json['sender'];

    if (senderData is Map<String, dynamic>) {
      senderObj = ChatParticipant.fromJson(senderData);
    } else if (senderData is String) {
      senderIdStr = senderData;
    } else if (senderData is List && senderData.isNotEmpty) {
      final firstSender = senderData.first;
      if (firstSender is Map<String, dynamic>) {
        senderObj = ChatParticipant.fromJson(firstSender);
      } else if (firstSender is String) {
        senderIdStr = firstSender;
      }
    }

    // Double check if id is nested in some other way or if it's a top level field
    final String id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final String chatId = json['chatId']?.toString() ?? '';

    // Support multiple keys for message text (text, message, content)
    final String text =
        json['text']?.toString() ??
        json['message']?.toString() ??
        json['content']?.toString() ??
        '';

    final List<String> attachments = List<String>.from(json['attachments'] ?? []);
    final String createdAt = json['createdAt']?.toString() ?? '';
    final String updatedAt = json['updatedAt']?.toString() ?? '';

    String? replyToId;
    ChatMessage? populatedReplyTo;
    final dynamic replyToData = json['replyTo'];
    if (replyToData is Map<String, dynamic>) {
      populatedReplyTo = ChatMessage.fromJson(replyToData);
      replyToId = populatedReplyTo.id;
    } else if (replyToData is String) {
      replyToId = replyToData;
    }

    return ChatMessage(
      id: id,
      chatId: chatId,
      sender: senderObj,
      senderId: senderIdStr ?? senderObj?.id,
      text: text,
      attachments: attachments,
      replyTo: replyToId,
      replyToMessage: populatedReplyTo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Check if this message was sent by the given userId
  bool isSentBy(String? currentUserId) {
    if (currentUserId == null || currentUserId.trim().isEmpty) return false;

    final String cleanCurrentId = currentUserId.trim();

    // Check direct senderId
    if (senderId != null && senderId!.trim().isNotEmpty) {
      if (senderId!.trim() == cleanCurrentId) return true;
    }

    // Check nested sender.id
    if (sender?.id != null && sender!.id.trim().isNotEmpty) {
      if (sender!.id.trim() == cleanCurrentId) return true;
    }

    return false;
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
