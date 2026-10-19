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

  /// Returns count of distinct conversations that have unread messages (Users + Live Chat)
  int get unreadDirectChatsCount =>
      chats.where((c) => (c.unreadCount > 0) || !c.isRead).length;

  int get unreadGroupsCount =>
      chatGroups.where((g) => (g.unreadCount > 0) || !g.isRead).length;

  int get unreadUsersCount {
    int userCount = unreadDirectChatsCount;
    final comm = communityRoom.value;
    if (comm != null && ((comm.unreadCount > 0) || !comm.isRead || unreadGroupsCount > 0)) {
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
    try {
      isGroupsLoading.value = true;
      final response = await communityService.getChatGroups();
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final groups = list
            .map((item) => CommunityRoom.fromJson(item as Map<String, dynamic>))
            .toList();
        chatGroups.assignAll(groups);
        if (groups.isNotEmpty) {
          String savedGroupId = await StorageService.getString('selected_chat_group_id');
          if (savedGroupId.isEmpty) {
            savedGroupId = await StorageService.getString('selected_community_service_area');
          }
          final match = groups.firstWhereOrNull((g) => g.id == savedGroupId);
          communityRoom.value = match ?? groups.first;
        }
        for (final g in groups) {
          ChatDraftService.loadDraft('community_${g.id}');
        }
        return;
      }
    } catch (e) {
      debugPrint('Error fetching chat groups: $e');
    } finally {
      isGroupsLoading.value = false;
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
      communityRoom.value = CommunityRoom(
        id: current.id,
        name: current.name,
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
          updatedChat.lastMessage = displayMsg.isNotEmpty ? displayMsg : "Attachment";
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
          int groupIndex =
              chatGroups.indexWhere((g) => g.id == newMessage.chatId);
          if (groupIndex != -1) {
            final grp = chatGroups[groupIndex];
            String displayMsg = newMessage.text.trim();
            if (displayMsg.isEmpty && newMessage.attachments.isNotEmpty) {
              displayMsg = "Attachment";
            }
            final bool isCurrentlyViewing =
                socketService.activeChatId == newMessage.chatId;
            final bool isFromOther = newMessage.sender?.id != null &&
                newMessage.sender!.id != userService.userId;
            final updatedGroup = CommunityRoom(
              id: grp.id,
              name: grp.name,
              status: grp.status,
              totalMembers: grp.totalMembers,
              lastMessage: displayMsg.isNotEmpty ? displayMsg : "Attachment",
              lastMessageAt: newMessage.createdAt,
              unreadCount: isCurrentlyViewing
                  ? 0
                  : (isFromOther ? grp.unreadCount + 1 : grp.unreadCount),
              isRead: isCurrentlyViewing
                  ? true
                  : (isFromOther ? false : grp.isRead),
            );
            chatGroups.removeAt(groupIndex);
            chatGroups.insert(0, updatedGroup);
            chatGroups.refresh();
            communityRoom.value = updatedGroup;
            communityRoom.refresh();
          } else {
            // If it's a new chat not in list, fetch all again
            fetchChats();
          }
        }
      }
    });

    // Listen for community messages
    ever(socketService.lastReceivedCommunityMessage, (newCommMsg) {
      if (newCommMsg != null) {
        debugPrint('📥 ChatController: Received community event payload: $newCommMsg');
        String? text;
        String? createdAt;
        String? senderId;

        dynamic msgData = newCommMsg;
        if (newCommMsg is Map) {
          if (newCommMsg['message'] != null) {
            msgData = newCommMsg['message'];
          } else if (newCommMsg['data'] != null) {
            msgData = newCommMsg['data'];
            if (msgData is Map && msgData['message'] != null) {
              msgData = msgData['message'];
            }
          }
        }

        if (msgData is Map) {
          text = msgData['text']?.toString() ??
              msgData['message']?.toString() ??
              msgData['content']?.toString();
          createdAt = msgData['createdAt']?.toString();
          final sData = msgData['sender'];
          if (sData is Map) {
            senderId = sData['id']?.toString() ??
                sData['_id']?.toString() ??
                sData['userId']?.toString();
          } else if (sData is String) {
            senderId = sData;
          }
        } else if (msgData is String) {
          text = msgData;
        }

        if (text != null && text.isNotEmpty) {
          final currentRoom = communityRoom.value ??
              CommunityRoom(
                name: "Live Chat",
              );
          final isFromOther =
              senderId != null && senderId != userService.userId;
          final isCurrentlyViewingCommunity = socketService.isCommunityActive;

          communityRoom.value = CommunityRoom(
            id: currentRoom.id,
            name: currentRoom.name.isNotEmpty ? currentRoom.name : "Live Chat",
            totalMembers: currentRoom.totalMembers,
            lastMessage: text,
            lastMessageAt: createdAt ?? DateTime.now().toIso8601String(),
            unreadCount: (isFromOther && !isCurrentlyViewingCommunity)
                ? (currentRoom.unreadCount + 1)
                : 0,
            isRead: isCurrentlyViewingCommunity
                ? true
                : (isFromOther ? false : currentRoom.isRead),
          );
          communityRoom.refresh();
          debugPrint('✨ ChatController: Updated Live Chat tile with lastMessage: $text');
        }
      }
    });
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
      final messageMatches =
          (group.lastMessage ?? '').toLowerCase().contains(query);
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
