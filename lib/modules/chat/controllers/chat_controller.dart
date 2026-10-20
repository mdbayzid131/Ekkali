import 'package:moeb_26/core/services/storege_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/chat_model.dart';
import 'package:moeb_26/data/models/chat_community_model.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/core/services/community_service.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/services/chat_draft_service.dart';

class ChatController extends GetxController {
  final SocketRepository socketRepo = Get.find();
  final SocketService socketService = Get.find();
  final CommunityService communityService = Get.find();
  final UserService userService = Get.find();

  var chats = <ChatPreview>[].obs;
  var chatGroups = <CommunityRoom>[].obs;
  var communityRoom = Rxn<CommunityRoom>();
  var searchController = "".obs;
  var isLoading = false.obs;
  var isGroupsLoading = false.obs;
  var selectedTab = 0.obs; // 0: Direct Chats, 1: Chat Groups
  var selectedChatIdForDelete = "".obs;
  final List<Worker> _socketWorkers = [];
  final Set<String> _seenGroupMessages = {};
  final Map<String, int> _groupRevisions = {};
  int _groupFetchVersion = 0;
  int _selectionVersion = 0;

  /// Returns count of distinct conversations that have unread messages (Users + Live Chat)
  int get unreadDirectChatsCount =>
      chats.where((c) => (c.unreadCount > 0) || !c.isRead).length;

  int get unreadGroupsCount =>
      chatGroups.where((g) => (g.unreadCount > 0) || !g.isRead).length;

  int get unreadUsersCount {
    int userCount = unreadDirectChatsCount;
    final comm = communityRoom.value;
    if (comm != null &&
        ((comm.unreadCount > 0) || !comm.isRead || unreadGroupsCount > 0)) {
      userCount += 1;
    }
    return userCount;
  }

  void toggleDeleteIcon(String chatId) {
    if (selectedChatIdForDelete.value == chatId) {
      selectedChatIdForDelete.value = "";
    } else {
      selectedChatIdForDelete.value = chatId;
    }
  }

  void clearDeleteSelection() {
    selectedChatIdForDelete.value = "";
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    fetchChats();
    fetchChatGroups();
    setupRealtimeUpdates();
  }

  Future<void> fetchChatGroups() async {
    final fetchVersion = ++_groupFetchVersion;
    final selectionVersion = _selectionVersion;
    final revisions = Map<String, int>.from(_groupRevisions);
    try {
      isGroupsLoading.value = true;
      final response = await communityService.getChatGroups();
      if (isClosed || fetchVersion != _groupFetchVersion) return;
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final groups = list
            .map((item) => CommunityRoom.fromJson(item as Map<String, dynamic>))
            .toList();
        for (var i = 0; i < groups.length; i++) {
          final current = chatGroups.firstWhereOrNull(
            (g) => g.id == groups[i].id,
          );
          if (current != null &&
              _groupRevisions[current.id] != revisions[current.id]) {
            groups[i] = groups[i].copyWith(
              lastMessage: current.lastMessage,
              lastMessageAt: current.lastMessageAt,
              unreadCount: current.unreadCount,
              isRead: current.isRead,
            );
          }
        }
        chatGroups.assignAll(groups);
        if (groups.isNotEmpty) {
          String savedGroupId = await StorageService.getString(
            'selected_chat_group_id',
          );
          if (savedGroupId.isEmpty) {
            savedGroupId = await StorageService.getString(
              'selected_community_service_area',
            );
          }
          if (isClosed || fetchVersion != _groupFetchVersion) return;
          if (selectionVersion != _selectionVersion) {
            savedGroupId = communityRoom.value?.id ?? savedGroupId;
          }
          final match = groups.firstWhereOrNull((g) => g.id == savedGroupId);
          final selected = match ?? groups.first;
          communityRoom.value = selected;
          await StorageService.setString('selected_chat_group_id', selected.id);

          if (communityRoom.value != null &&
              (communityRoom.value!.lastMessage == null ||
                  communityRoom.value!.lastMessage!.isEmpty)) {
            _fetchLatestMessageForGroup(communityRoom.value!.id);
          }
        }
        if (groups.isEmpty) communityRoom.value = null;
        for (final g in groups) {
          ChatDraftService.loadDraft('community_${g.id}');
        }
        return;
      }
    } catch (e) {
      debugPrint('Error fetching chat groups: $e');
    } finally {
      if (!isClosed && fetchVersion == _groupFetchVersion) {
        isGroupsLoading.value = false;
      }
    }
  }

  void selectGroup(CommunityRoom group) {
    _selectionVersion++;
    final idx = chatGroups.indexWhere((g) => g.id == group.id);
    if (idx != -1) {
      communityRoom.value = chatGroups[idx];
    } else {
      communityRoom.value = group;
    }
    StorageService.setString('selected_chat_group_id', group.id);
    communityRoom.refresh();

    if (communityRoom.value != null &&
        (communityRoom.value!.lastMessage == null ||
            communityRoom.value!.lastMessage!.isEmpty)) {
      _fetchLatestMessageForGroup(group.id);
    }
  }

  Future<void> syncSelectedGroupFromStorage() async {
    final savedGroupId = await StorageService.getString(
      'selected_chat_group_id',
    );
    if (isClosed) return;
    if (savedGroupId.isNotEmpty && chatGroups.isNotEmpty) {
      final match = chatGroups.firstWhereOrNull((g) => g.id == savedGroupId);
      if (match != null) {
        communityRoom.value = match;
        communityRoom.refresh();
      }
    }
    if (communityRoom.value != null &&
        (communityRoom.value!.lastMessage == null ||
            communityRoom.value!.lastMessage!.isEmpty)) {
      await _fetchLatestMessageForGroup(communityRoom.value!.id);
    }
  }

  Future<void> _fetchLatestMessageForGroup(String groupId) async {
    try {
      final response = await communityService.getGroupMessages(
        groupId,
        limit: 1,
      );
      if (!isClosed && response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        if (list.isNotEmpty) {
          final firstItem = list.first;
          String? text = firstItem['text']?.toString();
          if ((text == null || text.trim().isEmpty) &&
              firstItem['attachments'] is List &&
              (firstItem['attachments'] as List).isNotEmpty) {
            text = "Attachment";
          }
          final createdAt = firstItem['createdAt']?.toString();
          if (text != null && text.isNotEmpty) {
            updateGroupLastMessage(groupId, text, createdAt ?? '');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching latest message for group $groupId: $e');
    }
  }

  void updateGroupLastMessage(
    String groupId,
    String message,
    String timestamp,
  ) {
    final current =
        chatGroups.firstWhereOrNull((g) => g.id == groupId) ??
        (communityRoom.value?.id == groupId ? communityRoom.value : null);
    final previousTime = DateTime.tryParse(current?.lastMessageAt ?? '');
    final incomingTime = DateTime.tryParse(timestamp);
    if (previousTime != null &&
        incomingTime != null &&
        incomingTime.isBefore(previousTime)) {
      return;
    }
    _groupRevisions[groupId] = (_groupRevisions[groupId] ?? 0) + 1;
    int index = chatGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final grp = chatGroups[index];
      final updatedGroup = CommunityRoom(
        id: grp.id,
        name: grp.name,
        serviceArea: grp.serviceArea,
        status: grp.status,
        totalMembers: grp.totalMembers,
        lastMessage: message,
        lastMessageAt: timestamp.isNotEmpty ? timestamp : grp.lastMessageAt,
        unreadCount: grp.unreadCount,
        isRead: grp.isRead,
      );
      chatGroups[index] = updatedGroup;
      chatGroups.refresh();
    }

    if (communityRoom.value?.id == groupId) {
      final current = communityRoom.value!;
      communityRoom.value = CommunityRoom(
        id: current.id,
        name: current.name,
        serviceArea: current.serviceArea,
        status: current.status,
        totalMembers: current.totalMembers,
        lastMessage: message,
        lastMessageAt: timestamp.isNotEmpty ? timestamp : current.lastMessageAt,
        unreadCount: current.unreadCount,
        isRead: current.isRead,
      );
      communityRoom.refresh();
    }
  }

  Future<void> fetchCommunityRoom() async {
    await fetchChatGroups();
  }

  void markChatAsRead(String chatId) {
    int index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      chats[index].isRead = true;
      chats[index].unreadCount = 0;
      chats.refresh();
    }
  }

  void markGroupAsRead(String groupId) {
    int index = chatGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final current = chatGroups[index];
      chatGroups[index] = CommunityRoom(
        id: current.id,
        name: current.name,
        serviceArea: current.serviceArea,
        status: current.status,
        totalMembers: current.totalMembers,
        lastMessage: current.lastMessage,
        lastMessageAt: current.lastMessageAt,
        unreadCount: 0,
        isRead: true,
      );
      chatGroups.refresh();
    }
    if (communityRoom.value?.id == groupId) {
      markCommunityAsRead();
    }
  }

  void markCommunityAsRead() {
    if (communityRoom.value != null) {
      final current = communityRoom.value!;
      _groupRevisions[current.id] = (_groupRevisions[current.id] ?? 0) + 1;
      communityRoom.value = CommunityRoom(
        id: current.id,
        name: current.name,
        serviceArea: current.serviceArea,
        status: current.status,
        totalMembers: current.totalMembers,
        lastMessage: current.lastMessage,
        lastMessageAt: current.lastMessageAt,
        unreadCount: 0,
        isRead: true,
      );
      communityRoom.refresh();
    }
  }

  void setupRealtimeUpdates() {
    // Listen for global message updates to refresh the list
    _socketWorkers.add(
      ever(socketService.lastReceivedMessage, (newMessage) {
        if (newMessage != null) {
          // Find if this chat exists in our list
          int index = chats.indexWhere((c) => c.id == newMessage.chatId);
          if (index != -1) {
            final updatedChat = chats[index];
            String displayMsg = newMessage.text.trim();
            if (displayMsg.isEmpty && newMessage.attachments.isNotEmpty) {
              displayMsg = "Attachment";
            }
            updatedChat.lastMessage = displayMsg.isNotEmpty
                ? displayMsg
                : "Attachment";
            updatedChat.lastMessageAt = newMessage.createdAt;

            // If the user is currently viewing this exact chat, keep it marked as READ
            final bool isCurrentlyViewing =
                socketService.activeChatId == newMessage.chatId;

            if (isCurrentlyViewing) {
              updatedChat.isRead = true;
              updatedChat.unreadCount = 0;
            } else if (newMessage.sender?.id != null &&
                newMessage.sender!.id != userService.userId) {
              updatedChat.isRead = false;
              updatedChat.unreadCount = updatedChat.unreadCount + 1;
            }

            chats.removeAt(index);
            chats.insert(0, updatedChat);
            chats.refresh();
          } else {
            if (chatGroups.any((g) => g.id == newMessage.chatId)) {
              _handleGroupMessage(
                CommunityMessage(
                  id: newMessage.id,
                  chatId: newMessage.chatId,
                  sender:
                      newMessage.sender ??
                      ChatParticipant(id: newMessage.senderId ?? '', name: ''),
                  text: newMessage.text,
                  attachments: newMessage.attachments,
                  createdAt: newMessage.createdAt,
                  updatedAt: newMessage.updatedAt,
                ),
              );
            } else {
              fetchChats();
            }
          }
        }
      }),
    );

    _socketWorkers.add(
      ever(socketService.lastReceivedCommunityMessage, (event) {
        try {
          final payload = CommunityMessage.eventPayload(event);
          if (payload != null) {
            _handleGroupMessage(CommunityMessage.fromJson(payload));
          }
        } catch (e) {
          debugPrint('Error parsing community preview: $e');
        }
      }),
    );
  }

  void _handleGroupMessage(CommunityMessage message) {
    final groupId = message.chatId;
    if (groupId == null || groupId.isEmpty) return;
    final group = chatGroups.firstWhereOrNull((g) => g.id == groupId);
    if (group == null) return;
    final time = DateTime.tryParse(message.createdAt);
    final currentTime = DateTime.tryParse(group.lastMessageAt ?? '');
    if (time != null && currentTime != null && time.isBefore(currentTime)) {
      return;
    }
    final key = message.id.isNotEmpty
        ? '$groupId:${message.id}'
        : (message.createdAt.isNotEmpty
              ? '$groupId:${message.createdAt}:${message.sender.id}:${message.text}'
              : null);
    if (key != null && !_seenGroupMessages.add(key)) return;
    if (_seenGroupMessages.length > 200) {
      _seenGroupMessages.remove(_seenGroupMessages.first);
    }
    final text = message.text.trim().isNotEmpty
        ? message.text
        : (message.attachments.isNotEmpty ? 'Attachment' : '');
    if (text.isEmpty) return;
    updateGroupLastMessage(groupId, text, message.createdAt);
    final isViewing = socketService.activeChatId == groupId;
    final isFromOther =
        message.sender.id.isNotEmpty && message.sender.id != userService.userId;
    final updated = chatGroups
        .firstWhere((g) => g.id == groupId)
        .copyWith(
          unreadCount: isViewing
              ? 0
              : group.unreadCount + (isFromOther ? 1 : 0),
          isRead: isViewing ? true : (isFromOther ? false : group.isRead),
        );
    final index = chatGroups.indexWhere((g) => g.id == groupId);
    chatGroups.removeAt(index);
    chatGroups.insert(0, updated);
    if (communityRoom.value?.id == groupId) communityRoom.value = updated;
  }

  @override
  void onClose() {
    for (final worker in _socketWorkers) {
      worker.dispose();
    }
    super.onClose();
  }

  Future<void> fetchChats() async {
    try {
      isLoading.value = true;
      final result = await socketRepo.getChats();
      chats.assignAll(result);
      for (final chat in result) {
        ChatDraftService.loadDraft(chat.id);
      }
      filterChats(searchController.value);
    } catch (e) {
      debugPrint('Error fetching chats from API: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<ChatPreview> get filteredChats {
    final query = searchController.value.trim().toLowerCase();
    if (query.isEmpty) return chats;
    final currentUserId = userService.userId;
    return chats.where((chat) {
      final other = chat.getOtherParticipant(currentUserId);
      return other?.name.toLowerCase().contains(query) ?? false;
    }).toList();
  }

  List<CommunityRoom> get filteredGroups {
    final query = searchController.value.trim().toLowerCase();
    if (query.isEmpty) return chatGroups;
    return chatGroups.where((group) {
      final nameMatches = group.name.toLowerCase().contains(query);
      final messageMatches = (group.lastMessage ?? '').toLowerCase().contains(
        query,
      );
      return nameMatches || messageMatches;
    }).toList();
  }

  void filterChats(String query) {
    searchController.value = query;
  }

  Future<void> deleteChat(String chatId) async {
    try {
      isLoading.value = true;
      await socketRepo.deleteChat(chatId);
      chats.removeWhere((c) => c.id == chatId);
      filterChats(searchController.value);
      selectedChatIdForDelete.value = "";
      if (Get.isDialogOpen ?? false) Get.back();
      Helpers.showCustomSnackBar('Chat deleted successfully', isError: false);
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      Helpers.showCustomSnackBar('Failed to delete chat', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
