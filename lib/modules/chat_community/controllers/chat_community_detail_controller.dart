import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/services/community_service.dart';
import 'package:moeb_26/core/utils/media_picker_helper.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/chat_community_model.dart';
import 'package:moeb_26/data/models/chat_message_model.dart';
import 'package:moeb_26/data/models/chat_model.dart';
import 'package:moeb_26/core/services/chat_draft_service.dart';
import 'package:moeb_26/modules/chat/controllers/chat_controller.dart';

class CommunityChatDetailController extends GetxController {
  static const String _kSelectedChatGroupId = 'selected_chat_group_id';

  final UserService userService = Get.find<UserService>();
  final SocketService socketService = Get.find<SocketService>();
  final CommunityService communityService = Get.find<CommunityService>();

  final RxList<CommunityMessage> messages = <CommunityMessage>[].obs;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString nextCursor = ''.obs;
  final RxBool hasMore = true.obs;
  final RxBool isSending = false.obs;
  final RxList<File> selectedImages = <File>[].obs;
  final Rxn<CommunityMessage> replyingTo = Rxn<CommunityMessage>();
  Worker? _commWorker;

  late CommunityRoom room;
  final Rxn<CommunityRoom> selectedGroup = Rxn<CommunityRoom>();
  final RxList<CommunityRoom> groups = <CommunityRoom>[].obs;
  final RxBool isGroupsLoading = false.obs;
  Worker? _msgWorker;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is CommunityRoom) {
      room = Get.arguments as CommunityRoom;
      selectedGroup.value = room;
    } else {
      room = CommunityRoom(name: "Live Chat");
      selectedGroup.value = room;
    }
    socketService.isCommunityActive = true;
    _initDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().markGroupAsRead(room.id);
      }
    });
    scrollController.addListener(_onScroll);
    _initGroupsAndMessages();
  }

  void _initDraft() {
    _loadDraftForGroup(room.id);
    messageController.addListener(_onMessageChanged);
  }

  void _loadDraftForGroup(String groupId) {
    final draftKey = 'community_$groupId';
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
        } else if (saved.isEmpty) {
          messageController.clear();
        }
      });
    }
  }

  void _onMessageChanged() {
    ChatDraftService.saveDraft('community_${room.id}', messageController.text);
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

  Future<void> _initGroupsAndMessages() async {
    await fetchGroups();
    fetchMessages();
    setupSocket();
  }

  Future<void> fetchGroups() async {
    isGroupsLoading.value = true;
    try {
      final response = await communityService.getChatGroups();
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final loaded = list
            .map((item) => CommunityRoom.fromJson(item as Map<String, dynamic>))
            .toList();

        if (loaded.isNotEmpty) {
          groups.value = loaded;

          // Check if user previously selected a group from storage
          String savedGroupId =
              await StorageService.getString(_kSelectedChatGroupId);
          if (savedGroupId.isEmpty) {
            savedGroupId =
                await StorageService.getString('selected_community_service_area');
          }

          CommunityRoom? target;
          if (savedGroupId.isNotEmpty) {
            target = loaded.firstWhereOrNull((g) => g.id == savedGroupId);
          }
          target ??= loaded.firstWhereOrNull((g) => g.id == room.id);
          target ??= loaded.first;

          if (target.id != room.id) {
            room = target;
            selectedGroup.value = target;
            _switchGroup(target, isInitial: true);
          } else {
            selectedGroup.value = target;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching chat groups for live chat: $e");
    } finally {
      isGroupsLoading.value = false;
    }
  }

  void changeGroup(CommunityRoom newGroup) {
    if (selectedGroup.value?.id == newGroup.id) return;
    _switchGroup(newGroup);
  }

  void _switchGroup(CommunityRoom newGroup, {bool isInitial = false}) {
    if (!isInitial && selectedGroup.value != null) {
      ChatDraftService.saveDraft('community_${selectedGroup.value!.id}', messageController.text);
      socketService.leaveChat(selectedGroup.value!.id);
    }

    selectedGroup.value = newGroup;
    room = newGroup;
    StorageService.setString(_kSelectedChatGroupId, newGroup.id);

    _loadDraftForGroup(newGroup.id);

    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().markGroupAsRead(newGroup.id);
    }

    messages.clear();
    socketService.joinChat(newGroup.id);
    fetchMessages();
  }

  void setupSocket() {
    debugPrint('🔄 CommunityChatDetailController: Joining group chat: ${room.id}');
    socketService.joinChat(room.id);

    // 1. Listen for new messages via lastReceivedMessage
    _msgWorker = ever(socketService.lastReceivedMessage, (chatMsg) {
      if (chatMsg != null && chatMsg.chatId == room.id) {
        _handleIncomingChatMessage(chatMsg);
      }
    });

    // 2. Listen for community/broadcast events fallback
    _commWorker = ever(socketService.lastReceivedCommunityMessage, (data) {
      if (data != null) {
        try {
          dynamic msgData = data;
          if (data is Map && data['message'] != null) {
            msgData = data['message'];
          }
          if (msgData is Map<String, dynamic>) {
            final String msgChatId = msgData['chatId']?.toString() ??
                (msgData['chat'] is Map ? msgData['chat']['_id']?.toString() ?? '' : msgData['chat']?.toString() ?? '');
            if (msgChatId == room.id || msgChatId.isEmpty) {
              final newMsg = CommunityMessage.fromJson(msgData);
              _insertOrUpdateMessage(newMsg);
            }
          }
        } catch (e) {
          debugPrint('Error parsing real-time group message: $e');
        }
      }
    });
  }

  void _handleIncomingChatMessage(ChatMessage chatMsg) {
    final commMsg = CommunityMessage(
      id: chatMsg.id,
      chatId: room.id,
      sender: chatMsg.sender ??
          ChatParticipant(
            id: chatMsg.senderId ?? '',
            name: '',
          ),
      text: chatMsg.text,
      attachments: chatMsg.attachments,
      replyTo: chatMsg.replyTo,
      replyToMessage: chatMsg.replyToMessage != null
          ? CommunityMessage(
              id: chatMsg.replyToMessage!.id,
              chatId: room.id,
              sender: chatMsg.replyToMessage!.sender ??
                  ChatParticipant(
                    id: chatMsg.replyToMessage!.senderId ?? '',
                    name: '',
                  ),
              text: chatMsg.replyToMessage!.text,
              attachments: chatMsg.replyToMessage!.attachments,
              createdAt: chatMsg.replyToMessage!.createdAt,
              updatedAt: chatMsg.replyToMessage!.updatedAt,
            )
          : null,
      createdAt: chatMsg.createdAt,
      updatedAt: chatMsg.updatedAt,
    );
    _insertOrUpdateMessage(commMsg);
  }

  void _insertOrUpdateMessage(CommunityMessage newMsg) {
    int tempIndex = messages.indexWhere((m) => m.id.startsWith('cmsg_user_'));
    if (tempIndex != -1 && newMsg.sender.id == userService.userId) {
      messages[tempIndex] = newMsg;
    } else if (!messages.any((m) => m.id == newMsg.id)) {
      messages.insert(0, newMsg);
    }
  }

  Future<void> fetchMessages() async {
    try {
      isLoading.value = true;
      hasMore.value = true;
      nextCursor.value = '';
      final response = await communityService.getGroupMessages(
        room.id,
        limit: 50,
      );
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final fetched = list
            .map((item) => CommunityMessage.fromJson(item as Map<String, dynamic>))
            .toList();

        final cursorData = response.data['cursor'];
        if (cursorData is Map) {
          nextCursor.value = cursorData['nextCursor']?.toString() ?? '';
          hasMore.value = cursorData['hasMore'] == true;
        } else {
          hasMore.value = false;
        }

        // Check if list is oldest-first (ASC)
        if (fetched.length > 1) {
          final firstDate = DateTime.tryParse(fetched.first.createdAt);
          final lastDate = DateTime.tryParse(fetched.last.createdAt);
          if (firstDate != null && lastDate != null && firstDate.isBefore(lastDate)) {
            messages.assignAll(fetched.reversed.toList());
          } else {
            messages.assignAll(fetched);
          }
        } else {
          messages.assignAll(fetched);
        }
      }
    } catch (e) {
      debugPrint('Error fetching group messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreMessages() async {
    if (!hasMore.value || isLoadingMore.value || nextCursor.value.isEmpty) return;
    try {
      isLoadingMore.value = true;
      final response = await communityService.getGroupMessages(
        room.id,
        cursor: nextCursor.value,
        limit: 50,
      );
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final fetched = list
            .map((item) => CommunityMessage.fromJson(item as Map<String, dynamic>))
            .toList();

        final cursorData = response.data['cursor'];
        if (cursorData is Map) {
          nextCursor.value = cursorData['nextCursor']?.toString() ?? '';
          hasMore.value = cursorData['hasMore'] == true;
        } else {
          hasMore.value = false;
        }

        if (fetched.isNotEmpty) {
          List<CommunityMessage> toAppend;
          if (fetched.length > 1) {
            final firstDate = DateTime.tryParse(fetched.first.createdAt);
            final lastDate = DateTime.tryParse(fetched.last.createdAt);
            if (firstDate != null && lastDate != null && firstDate.isBefore(lastDate)) {
              toAppend = fetched.reversed.toList();
            } else {
              toAppend = fetched;
            }
          } else {
            toAppend = fetched;
          }

          for (var msg in toAppend) {
            if (!messages.any((m) => m.id == msg.id)) {
              messages.add(msg);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading more community messages: $e');
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

  void replyToMessage(CommunityMessage message) {
    replyingTo.value = message;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  void copyMessage(CommunityMessage message) {
    final regex = RegExp(r'^\[REPLY:([^|]*)\|([^\]]*)\]([\s\S]*)$');
    final match = regex.firstMatch(message.text);
    final String cleanText = match != null ? (match.group(3) ?? '') : message.text;

    Clipboard.setData(ClipboardData(text: cleanText));
    Helpers.showCustomSnackBar('Message copied to clipboard', isError: false);
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty && selectedImages.isEmpty) return;

    String? replyToId;
    CommunityMessage? quotedMessage;
    if (replyingTo.value != null) {
      quotedMessage = replyingTo.value;
      replyToId = quotedMessage!.id;
      replyingTo.value = null;
    }

    final tempId = 'cmsg_user_${DateTime.now().millisecondsSinceEpoch}';
    final currentUserId = userService.userId;
    final List<File> imagesToSend = selectedImages.toList();

    final tempMsg = CommunityMessage(
      id: tempId,
      chatId: room.id,
      sender: ChatParticipant(
        id: currentUserId,
        name: 'You',
        profilePicture: null,
      ),
      text: text,
      attachments: [],
      replyTo: replyToId,
      replyToMessage: quotedMessage,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    // Immediately show on UI at index 0 (bottom of screen)
    messages.insert(0, tempMsg);
    messageController.clear();
    selectedImages.clear();
    ChatDraftService.clearDraft('community_${room.id}');

    try {
      final response = await communityService.sendGroupMessage(
        room.id,
        text: text,
        attachments: imagesToSend,
        replyTo: replyToId,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['data'] != null) {
          final sent = CommunityMessage.fromJson(response.data['data']);
          int index = messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            messages[index] = sent;
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending group message: $e');
      messages.removeWhere((m) => m.id == tempId);
      selectedImages.addAll(imagesToSend);
      messageController.text = text;
      ChatDraftService.saveDraft('community_${room.id}', text);
      Helpers.showCustomSnackBar('Failed to send group message', isError: true);
    }
  }

  @override
  void onClose() {
    socketService.isCommunityActive = false;
    socketService.leaveChat(room.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().markGroupAsRead(room.id);
      }
    });
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _msgWorker?.dispose();
    _commWorker?.dispose();
    messageController.removeListener(_onMessageChanged);
    ChatDraftService.saveDraft('community_${room.id}', messageController.text);
    messageController.dispose();
    super.onClose();
  }
}
