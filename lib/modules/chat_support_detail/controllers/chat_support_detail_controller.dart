import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/chat_message_model.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/support_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/services/chat_draft_service.dart';

class SupportChatController extends GetxController {
  final SupportService _supportService = Get.find<SupportService>();
  final SocketService socketService = Get.find<SocketService>();
  final UserService userService = Get.find<UserService>();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final messageController = TextEditingController();

  late String chatId;

  @override
  void onInit() {
    super.onInit();
    chatId = Get.arguments['chatId'];
    _initDraft();
    _initializeChat();
  }

  void _initDraft() {
    final draftKey = 'support_$chatId';
    final cached = ChatDraftService.getDraft(draftKey);
    if (cached.isNotEmpty) {
      messageController.text = cached;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: cached.length),
      );
    } else {
      ChatDraftService.loadDraft(draftKey).then((saved) {
        if (saved.isNotEmpty && messageController.text.isEmpty) {
          messageController.text = saved;
          messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: saved.length),
          );
        }
      });
    }
    messageController.addListener(_onMessageChanged);
  }

  void _onMessageChanged() {
    ChatDraftService.saveDraft('support_$chatId', messageController.text);
  }

  Future<void> _initializeChat() async {
    // If we received userId from arguments, set it immediately
    final String? argUserId = Get.arguments['userId'];
    if (argUserId != null && argUserId.isNotEmpty) {
      userService.userId = argUserId;
      debugPrint(
        "✅ SupportChatController: Set userId from arguments: $argUserId",
      );
    } else if (userService.userId.isEmpty) {
      // Fallback to fetching if not passed
      await userService.fetchUserId();
    }
    fetchMessages();
    setupSocketListeners();
  }

  Future<void> fetchMessages() async {
    try {
      isLoading.value = true;
      final response = await _supportService.getMessages(chatId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = response.data['data'] ?? [];
        messages.assignAll(data.map((m) => ChatMessage.fromJson(m)).toList());
      }
    } catch (e) {
      debugPrint("Error fetching support messages: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void setupSocketListeners() {
    // Join the support chat room
    debugPrint('🔄 SupportChatController: Joining room $chatId');
    socketService.joinRoom(chatId);

    // Listen for new messages
    ever(socketService.lastReceivedMessage, (ChatMessage? message) {
      if (message != null && message.chatId == chatId) {
        debugPrint(
          '📥 SupportChatController: Received message via socket: ${message.text}',
        );
        // Check if message already exists to avoid duplicates
        if (!messages.any((m) => m.id == message.id)) {
          messages.insert(0, message);
        }
      }
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    ChatDraftService.clearDraft('support_$chatId');

    try {
      // Use API for sending message as requested
      final response = await _supportService.sendMessage(chatId, text);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newMessage = ChatMessage.fromJson(response.data['data']);

        // If the socket hasn't pushed the message yet, add it manually
        if (!messages.any((m) => m.id == newMessage.id)) {
          messages.insert(0, newMessage);
        }
      }
    } catch (e) {
      debugPrint("Error sending support message: $e");
      messageController.text = text;
      ChatDraftService.saveDraft('support_$chatId', text);
      Helpers.showCustomSnackBar("Failed to send message", isError: true);
    }
  }

  @override
  void onClose() {
    socketService.leaveRoom(chatId);
    messageController.removeListener(_onMessageChanged);
    ChatDraftService.saveDraft('support_$chatId', messageController.text);
    messageController.dispose();
    super.onClose();
  }
}
