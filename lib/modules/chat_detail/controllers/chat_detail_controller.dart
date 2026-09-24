import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moeb_26/core/utils/media_picker_helper.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/chat_model.dart';
import 'package:moeb_26/data/models/chat_message_model.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/services/chat_draft_service.dart';
import 'package:moeb_26/modules/chat/controllers/chat_controller.dart';

class ChatDetailController extends GetxController {
  final SocketRepository socketRepo = Get.find();
  final SocketService socketService = Get.find();
  final UserService userService = Get.find();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString nextCursor = ''.obs;
  final RxBool hasMore = true.obs;
  final RxList<File> selectedImages = <File>[].obs;
  final Rxn<ChatMessage> replyingTo = Rxn<ChatMessage>();
  Worker? _messageWorker;

  late ChatPreview chat;

  @override
  void onInit() {
    super.onInit();
    chat = Get.arguments;
    socketService.activeChatId = chat.id;
    _initDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().markChatAsRead(chat.id);
      }
    });
    scrollController.addListener(_onScroll);
    _initWithUserId();
    setupSocket();
  }

  void _initDraft() {
    final cached = ChatDraftService.getDraft(chat.id);
    if (cached.isNotEmpty) {
      messageController.text = cached;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: cached.length),
      );
    } else {
      ChatDraftService.loadDraft(chat.id).then((saved) {
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
    ChatDraftService.saveDraft(chat.id, messageController.text);
  }

  void _onScroll() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        hasMore.value &&
        !isLoadingMore.value &&
        !isLoading.value &&
        nextCursor.value.isNotEmpty) {
      loadMoreMessages();
    }
  }

  Future<void> _initWithUserId() async {
    if (userService.userId.isEmpty) {
      await userService.fetchUserId();
    }
    fetchMessages();
  }

  void setupSocket() {
    debugPrint(
      '🔄 ChatDetailController: Setting up socket for chatId: ${chat.id}',
    );
    socketService.joinChat(chat.id);

    _messageWorker = ever(socketService.lastReceivedMessage, (newMessage) {
      if (newMessage != null &&
          (newMessage.text.trim().isNotEmpty ||
              newMessage.attachments.isNotEmpty)) {
        if (newMessage.chatId == chat.id) {
          int tempIndex = messages.indexWhere((m) => m.id.startsWith('temp_'));

          if (tempIndex != -1 && newMessage.isSentBy(userService.userId)) {
            messages[tempIndex] = newMessage;
          } else if (!messages.any((m) => m.id == newMessage.id)) {
            messages.insert(0, newMessage);
          }
        }
      }
    });
  }

  Future<void> fetchMessages() async {
    try {
      isLoading.value = true;
      hasMore.value = true;
      nextCursor.value = '';
      final response = await socketRepo.getMessagesRaw(chat.id, limit: 40);
      if (response.statusCode == 200 && response.data != null) {
        final List data = response.data['data'] ?? [];
        final fetchedMessages =
            data.map((json) => ChatMessage.fromJson(json)).toList();

        final cursorData = response.data['cursor'];
        if (cursorData is Map) {
          nextCursor.value = cursorData['nextCursor']?.toString() ?? '';
          hasMore.value = cursorData['hasMore'] == true;
        } else {
          hasMore.value = false;
        }

        if (fetchedMessages.length > 1) {
          final firstDate = DateTime.tryParse(fetchedMessages.first.createdAt);
          final lastDate = DateTime.tryParse(fetchedMessages.last.createdAt);
          if (firstDate != null &&
              lastDate != null &&
              firstDate.isBefore(lastDate)) {
            messages.assignAll(fetchedMessages.reversed.toList());
          } else {
            messages.assignAll(fetchedMessages);
          }
        } else {
          messages.assignAll(fetchedMessages);
        }
      }
      update();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreMessages() async {
    if (!hasMore.value || isLoadingMore.value || nextCursor.value.isEmpty) return;
    try {
      isLoadingMore.value = true;
      final response = await socketRepo.getMessagesRaw(
        chat.id,
        cursor: nextCursor.value,
        limit: 40,
      );
      if (response.statusCode == 200 && response.data != null) {
        final List data = response.data['data'] ?? [];
        final fetchedMessages =
            data.map((json) => ChatMessage.fromJson(json)).toList();

        final cursorData = response.data['cursor'];
        if (cursorData is Map) {
          nextCursor.value = cursorData['nextCursor']?.toString() ?? '';
          hasMore.value = cursorData['hasMore'] == true;
        } else {
          hasMore.value = false;
        }

        if (fetchedMessages.isNotEmpty) {
          List<ChatMessage> toAppend;
          if (fetchedMessages.length > 1) {
            final firstDate = DateTime.tryParse(fetchedMessages.first.createdAt);
            final lastDate = DateTime.tryParse(fetchedMessages.last.createdAt);
            if (firstDate != null &&
                lastDate != null &&
                firstDate.isBefore(lastDate)) {
              toAppend = fetchedMessages.reversed.toList();
            } else {
              toAppend = fetchedMessages;
            }
          } else {
            toAppend = fetchedMessages;
          }

          for (var msg in toAppend) {
            if (!messages.any((m) => m.id == msg.id)) {
              messages.add(msg);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> pickImage(BuildContext context) async {
    final List<File>? images = await MediaPickerHelper.pickMultiImages(context);
    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        final compressed = await Helpers.compressImage(image);
        selectedImages.add(compressed);
      }
    }
  }

  Future<void> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        final compressed = await Helpers.compressImage(File(image.path));
        selectedImages.add(compressed);
      }
    } catch (e) {
      Helpers.error('Error picking from camera: $e');
      Helpers.showCustomSnackBar(
        'Could not open camera. Please check app permissions in settings.',
        isError: true,
      );
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  void replyToMessage(ChatMessage message) {
    replyingTo.value = message;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  void copyMessage(ChatMessage message) {
    final regex = RegExp(r'^\[REPLY:([^|]*)\|([^\]]*)\]([\s\S]*)$');
    final match = regex.firstMatch(message.text);
    final String cleanText = match != null
        ? (match.group(3) ?? '')
        : message.text;

    Clipboard.setData(ClipboardData(text: cleanText));
    Helpers.showCustomSnackBar('Message copied to clipboard', isError: false);
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isNotEmpty || selectedImages.isNotEmpty) {
      String? replyToId;
      ChatMessage? quotedMessage;
      if (replyingTo.value != null) {
        quotedMessage = replyingTo.value;
        replyToId = quotedMessage!.id;
        replyingTo.value = null;
      }

      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      final List<File> imagesToSend = selectedImages.toList();
      selectedImages.clear();

      final tempMessage = ChatMessage(
        id: tempId,
        chatId: chat.id,
        text: text,
        senderId: userService.userId,
        sender: ChatParticipant(id: userService.userId, name: 'You'),
        replyTo: replyToId,
        replyToMessage: quotedMessage,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      messages.insert(0, tempMessage);
      messageController.clear();
      ChatDraftService.clearDraft(chat.id);

      try {
        final sentMessage = await socketRepo.sendMessage(
          chat.id,
          text,
          attachments: imagesToSend,
          replyTo: replyToId,
        );
        if (sentMessage != null) {
          int index = messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            messages[index] = sentMessage;
          }
        }
      } catch (e) {
        messages.removeWhere((m) => m.id == tempId);
        selectedImages.addAll(imagesToSend);
        messageController.text = text;
        ChatDraftService.saveDraft(chat.id, text);
        Helpers.showCustomSnackBar('Failed to send message', isError: true);
      }
    }
  }

  @override
  void onClose() {
    final String closingChatId = chat.id;
    if (socketService.activeChatId == closingChatId) {
      socketService.activeChatId = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().markChatAsRead(closingChatId);
      }
    });
    scrollController.dispose();
    socketService.leaveChat(closingChatId);
    _messageWorker?.dispose();
    messageController.removeListener(_onMessageChanged);
    ChatDraftService.saveDraft(chat.id, messageController.text);
    messageController.dispose();
    super.onClose();
  }
}
