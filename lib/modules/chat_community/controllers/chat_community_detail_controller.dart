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
  int _messageRequestVersion = 0;
  bool _ready = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().markGroupAsRead(room.id);
      }
    });
    scrollController.addListener(_onScroll);
    _initGroupsAndMessages();
  }

  void _initDraft() {
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
        if (isClosed ||
            room.id != groupId ||
            messageController.text.isNotEmpty) {
          return;
        }
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
    if (isClosed) return;
    if (selectedGroup.value == null || room.id == 'global') return;
    _ready = true;
    _initDraft();
    _loadDraftForGroup(room.id);
    setupSocket();
    await fetchMessages();
  }

  Future<void> fetchGroups() async {
    isGroupsLoading.value = true;
    try {
      final response = await communityService.getChatGroups();
      if (isClosed) return;
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final loaded = list
            .map((item) => CommunityRoom.fromJson(item as Map<String, dynamic>))
            .toList();

        if (loaded.isEmpty) {
          selectedGroup.value = null;
          return;
        }
        if (loaded.isNotEmpty) {
          groups.value = loaded;

          // Check if user previously selected a group from storage
          String savedGroupId = await StorageService.getString(
            _kSelectedChatGroupId,
          );
          if (savedGroupId.isEmpty) {
            savedGroupId = await StorageService.getString(
              'selected_community_service_area',
            );
          }

          if (isClosed) return;
          CommunityRoom? target;
          if (savedGroupId.isNotEmpty) {
            target = loaded.firstWhereOrNull((g) => g.id == savedGroupId);
          }
          target ??= loaded.firstWhereOrNull((g) => g.id == room.id);
          target ??= loaded.first;

          room = target;
          selectedGroup.value = target;
          await StorageService.setString(_kSelectedChatGroupId, target.id);
          if (isClosed) return;
          if (Get.isRegistered<ChatController>()) {
            Get.find<ChatController>().selectGroup(target);
            Get.find<ChatController>().markGroupAsRead(target.id);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching chat groups for live chat: $e");
    } finally {
      if (!isClosed) isGroupsLoading.value = false;
    }
  }

  void changeGroup(CommunityRoom newGroup) {
    if (!_ready || isClosed || selectedGroup.value?.id == newGroup.id) return;
    _switchGroup(newGroup);
  }

  void _switchGroup(CommunityRoom newGroup) {
    if (selectedGroup.value != null) {
      ChatDraftService.saveDraft(
        'community_${selectedGroup.value!.id}',
        messageController.text,
      );
      socketService.leaveChat(selectedGroup.value!.id);
    }

    // Do not copy the old group's draft, attachments or reply into the new group.
    messageController.removeListener(_onMessageChanged);
    messageController.clear();
    selectedImages.clear();
    replyingTo.value = null;
    isLoadingMore.value = false;
    selectedGroup.value = newGroup;
    room = newGroup;
    StorageService.setString(_kSelectedChatGroupId, newGroup.id);

    _loadDraftForGroup(newGroup.id);
    messageController.addListener(_onMessageChanged);

    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().selectGroup(newGroup);
      Get.find<ChatController>().markGroupAsRead(newGroup.id);
    }

    messages.clear();
    socketService.joinChat(newGroup.id);
    fetchMessages();
  }

  void setupSocket() {
    debugPrint(
      '🔄 CommunityChatDetailController: Joining group chat: ${room.id}',
    );
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
          final payload = CommunityMessage.eventPayload(data);
          if (payload != null && payload['chatId'] == room.id) {
            _insertOrUpdateMessage(CommunityMessage.fromJson(payload));
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
      sender:
          chatMsg.sender ??
          ChatParticipant(id: chatMsg.senderId ?? '', name: ''),
      text: chatMsg.text,
      attachments: chatMsg.attachments,
      replyTo: chatMsg.replyTo,
      replyToMessage: chatMsg.replyToMessage != null
          ? CommunityMessage(
              id: chatMsg.replyToMessage!.id,
              chatId: room.id,
              sender:
                  chatMsg.replyToMessage!.sender ??
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
    if (newMsg.id.isEmpty) return;
    int tempIndex = messages.indexWhere(
      (m) => m.id.startsWith('cmsg_user_') && m.text == newMsg.text,
    );
    if (tempIndex != -1 && newMsg.sender.id == userService.userId) {
      messages[tempIndex] = newMsg;
    } else if (!messages.any((m) => m.id == newMsg.id)) {
      messages.insert(0, newMsg);
    }

    String displayMsg = newMsg.text.trim();
    if (displayMsg.isEmpty && newMsg.attachments.isNotEmpty) {
      displayMsg = "Attachment";
    }
    if (displayMsg.isNotEmpty && Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().updateGroupLastMessage(
        room.id,
        displayMsg,
        newMsg.createdAt,
      );
    }
  }

  Future<void> fetchMessages() async {
    final groupId = room.id;
    final requestVersion = ++_messageRequestVersion;
    final startingIds = messages.map((m) => m.id).toSet();
    try {
      isLoading.value = true;
      hasMore.value = true;
      nextCursor.value = '';
      final response = await communityService.getGroupMessages(
        groupId,
        limit: 50,
      );
      if (isClosed ||
          requestVersion != _messageRequestVersion ||
          room.id != groupId) {
        return;
      }
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final fetched = list
            .map(
              (item) => CommunityMessage.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        final cursorData = response.data['cursor'];
        if (cursorData is Map) {
          nextCursor.value = cursorData['nextCursor']?.toString() ?? '';
          hasMore.value = cursorData['hasMore'] == true;
        } else {
          hasMore.value = false;
        }

        // Keep live arrivals and pending sends that happened during this request.
        final retained = messages.where(
          (m) => !startingIds.contains(m.id) || m.id.startsWith('cmsg_user_'),
        );
        final combined = <String, CommunityMessage>{
          for (final message in retained) message.id: message,
          for (final message in fetched) message.id: message,
        }.values.toList();
        combined.sort(
          (a, b) => (DateTime.tryParse(b.createdAt) ?? DateTime(1970))
              .compareTo(DateTime.tryParse(a.createdAt) ?? DateTime(1970)),
        );
        messages.assignAll(combined);

        if (messages.isNotEmpty) {
          final topMsg = messages.first;
          String latestText = topMsg.text.trim();
          if (latestText.isEmpty && topMsg.attachments.isNotEmpty) {
            latestText = "Attachment";
          }
          if (latestText.isNotEmpty && Get.isRegistered<ChatController>()) {
            Get.find<ChatController>().updateGroupLastMessage(
              room.id,
              latestText,
              topMsg.createdAt,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching group messages: $e');
    } finally {
      if (!isClosed && requestVersion == _messageRequestVersion) {
        isLoading.value = false;
      }
    }
  }

  Future<void> loadMoreMessages() async {
    if (!hasMore.value || isLoadingMore.value || nextCursor.value.isEmpty) {
      return;
    }
    final groupId = room.id;
    final requestVersion = _messageRequestVersion;
    try {
      isLoadingMore.value = true;
      final response = await communityService.getGroupMessages(
        groupId,
        cursor: nextCursor.value,
        limit: 50,
      );
      if (isClosed ||
          requestVersion != _messageRequestVersion ||
          room.id != groupId) {
        return;
      }
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final fetched = list
            .map(
              (item) => CommunityMessage.fromJson(item as Map<String, dynamic>),
            )
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
            if (firstDate != null &&
                lastDate != null &&
                firstDate.isBefore(lastDate)) {
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
      if (!isClosed && requestVersion == _messageRequestVersion) {
        isLoadingMore.value = false;
      }
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
    final String cleanText = match != null
        ? (match.group(3) ?? '')
        : message.text;

    Clipboard.setData(ClipboardData(text: cleanText));
    Helpers.showCustomSnackBar('Message copied to clipboard', isError: false);
  }

  Future<void> sendMessage() async {
    if (!_ready || isClosed || isSending.value) return;
    final groupId = room.id;
    final text = messageController.text.trim();
    if (text.isEmpty && selectedImages.isEmpty) return;
    isSending.value = true;

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
      chatId: groupId,
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
    ChatDraftService.clearDraft('community_$groupId');

    try {
      final response = await communityService.sendGroupMessage(
        groupId,
        text: text,
        attachments: imagesToSend,
        replyTo: replyToId,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw StateError('Failed to send group message');
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['data'] != null) {
          final sent = CommunityMessage.fromJson(response.data['data']);
          if (Get.isRegistered<ChatController>()) {
            Get.find<ChatController>().updateGroupLastMessage(
              groupId,
              sent.text.trim().isNotEmpty ? sent.text : 'Attachment',
              sent.createdAt,
            );
          }
          if (isClosed || room.id != groupId) return;
          int index = messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            messages[index] = sent;
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending group message: $e');
      if (isClosed || room.id != groupId) {
        if (ChatDraftService.getDraft('community_$groupId').isEmpty) {
          ChatDraftService.saveDraft('community_$groupId', text);
        }
        return;
      }
      messages.removeWhere((m) => m.id == tempId);
      selectedImages.addAll(imagesToSend);
      final currentDraft = messageController.text;
      messageController.text = currentDraft.isEmpty
          ? text
          : [text, currentDraft].join('\n');
      ChatDraftService.saveDraft('community_$groupId', messageController.text);
      Helpers.showCustomSnackBar('Failed to send group message', isError: true);
    } finally {
      if (!isClosed) isSending.value = false;
    }
  }

  @override
  void onClose() {
    socketService.isCommunityActive = false;
    socketService.leaveChat(room.id);
    final closingGroupId = room.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().markGroupAsRead(closingGroupId);
      }
    });
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _msgWorker?.dispose();
    _commWorker?.dispose();
    messageController.removeListener(_onMessageChanged);
    if (_ready) {
      ChatDraftService.saveDraft(
        'community_$closingGroupId',
        messageController.text,
      );
    }
    messageController.dispose();
    super.onClose();
  }
}
