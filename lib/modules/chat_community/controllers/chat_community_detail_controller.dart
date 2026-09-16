import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/services/user_profile_service.dart';
import 'package:moeb_26/core/services/community_service.dart';
import 'package:moeb_26/core/utils/media_picker_helper.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/chat_community_model.dart';
import 'package:moeb_26/data/models/chat_model.dart';
import 'package:moeb_26/modules/chat/controllers/chat_controller.dart';

class CommunityChatDetailController extends GetxController {
  static const String _kSelectedCommunityServiceArea =
      'selected_community_service_area';

  final UserService userService = Get.find<UserService>();
  final SocketService socketService = Get.find<SocketService>();
  final CommunityService communityService = Get.find<CommunityService>();
  final UserProfileService _profileService = Get.find<UserProfileService>();

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
  var selectedState = ''.obs;
  final RxList<String> states = <String>[].obs;
  final RxBool isServiceAreasLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    room = Get.arguments;
    socketService.isCommunityActive = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().markCommunityAsRead();
      }
    });
    scrollController.addListener(_onScroll);
    _initServiceAreaAndMessages();
  }

  Future<void> _initServiceAreaAndMessages() async {
    // 1. Check local storage first (if user manually switched before)
    final savedArea =
        await StorageService.getString(_kSelectedCommunityServiceArea);
    if (savedArea.isNotEmpty) {
      selectedState.value = savedArea;
    } else if (room.serviceArea.isNotEmpty) {
      selectedState.value = room.serviceArea;
    }

    // 2. Fetch User Profile to get user's current serviceArea from API if still not set
    if (selectedState.value.isEmpty) {
      try {
        final profileRes = await _profileService.getUserProfile();
        if (profileRes.statusCode == 200 && profileRes.data?['data'] != null) {
          final userArea = profileRes.data['data']['serviceArea']?.toString();
          if (userArea != null && userArea.isNotEmpty) {
            selectedState.value = userArea;
          }
        }
      } catch (e) {
        debugPrint("Error fetching user profile service area: $e");
      }
    }

    // 3. Fallback default if still empty
    if (selectedState.value.isEmpty) {
      selectedState.value = 'New York Metro';
    }

    await fetchServiceAreas();
    fetchMessages();
    setupSocket();
  }

  Future<void> fetchServiceAreas() async {
    isServiceAreasLoading.value = true;
    try {
      final response = await _profileService.getServiceAreas();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data is List) {
          final List<String> loadedAreas = data
              .map((item) {
                if (item is Map) {
                  return item['areaName']?.toString() ??
                      item['name']?.toString() ??
                      '';
                }
                return item.toString();
              })
              .where((name) => name.trim().isNotEmpty)
              .toList();

          if (loadedAreas.isNotEmpty) {
            states.value = loadedAreas;

            // Sync selected state with dynamic list
            if (selectedState.value.isNotEmpty) {
              final String areaLower = selectedState.value.toLowerCase();
              final matched = states.firstWhereOrNull(
                (s) =>
                    s.toLowerCase() == areaLower ||
                    areaLower.contains(s.toLowerCase()) ||
                    s.toLowerCase().contains(areaLower),
              );
              if (matched != null) {
                selectedState.value = matched;
              } else if (!states.contains(selectedState.value)) {
                selectedState.value = states.first;
              }
            } else {
              selectedState.value = states.first;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching dynamic service areas for live chat: $e");
    } finally {
      isServiceAreasLoading.value = false;
    }
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

  void changeState(String newState) {
    if (selectedState.value == newState) return;
    selectedState.value = newState;
    StorageService.setString(_kSelectedCommunityServiceArea, newState);
    socketService.joinCommunity(newState);
    fetchMessages();
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().fetchCommunityRoom(serviceArea: newState);
    }
  }

  void setupSocket() {
    final String currentArea = selectedState.value;
    debugPrint('🔄 CommunityChatDetailController: Joining community: $currentArea');
    socketService.joinCommunity(currentArea);

    _commWorker = ever(socketService.lastReceivedCommunityMessage, (data) {
      if (data != null) {
        try {
          dynamic msgData = data;
          if (data is Map && data['message'] != null) {
            msgData = data['message'];
          }
          if (msgData is Map<String, dynamic>) {
            final newMsg = CommunityMessage.fromJson(msgData);
            int tempIndex = messages.indexWhere((m) => m.id.startsWith('cmsg_user_'));
            if (tempIndex != -1 && newMsg.sender.id == userService.userId) {
              messages[tempIndex] = newMsg;
            } else if (!messages.any((m) => m.id == newMsg.id)) {
              messages.insert(0, newMsg);
            }
          }
        } catch (e) {
          debugPrint('Error parsing real-time community message: $e');
        }
      }
    });
  }

  Future<void> fetchMessages() async {
    try {
      isLoading.value = true;
      hasMore.value = true;
      nextCursor.value = '';
      final response = await communityService.getCommunityMessages(
        serviceArea: selectedState.value,
        limit: 40,
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
      debugPrint('Error fetching community messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreMessages() async {
    if (!hasMore.value || isLoadingMore.value || nextCursor.value.isEmpty) return;
    try {
      isLoadingMore.value = true;
      final response = await communityService.getCommunityMessages(
        serviceArea: selectedState.value,
        cursor: nextCursor.value,
        limit: 40,
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
      serviceArea: selectedState.value,
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

    try {
      final response = await communityService.sendCommunityMessage(
        text: text,
        attachments: imagesToSend,
        replyTo: replyToId,
        serviceArea: selectedState.value,
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
      debugPrint('Error sending community message: $e');
      messages.removeWhere((m) => m.id == tempId);
      selectedImages.addAll(imagesToSend);
      Helpers.showCustomSnackBar('Failed to send broadcast message', isError: true);
    }
  }

  @override
  void onClose() {
    socketService.isCommunityActive = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().markCommunityAsRead();
      }
    });
    scrollController.dispose();
    _commWorker?.dispose();
    messageController.dispose();
    super.onClose();
  }
}
