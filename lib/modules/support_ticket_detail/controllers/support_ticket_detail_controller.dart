import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/services/chat_draft_service.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/support_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/utils/media_picker_helper.dart';
import 'package:moeb_26/data/models/support_ticket_model.dart';

class SupportTicketDetailController extends GetxController {
  final SupportService _supportService = Get.find<SupportService>();
  final SocketService socketService = Get.find<SocketService>();
  final UserService userService = Get.find<UserService>();

  final RxList<SupportMessage> messages = <SupportMessage>[].obs;
  final RxList<File> selectedAttachments = <File>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final TextEditingController messageController = TextEditingController();

  late String ticketId;
  final RxString subject = 'Support Ticket'.obs;
  final RxString status = 'PENDING'.obs;
  final RxString createdAt = ''.obs;
  final RxString ticketUserId = ''.obs;
  final RxString currentUserName = ''.obs;

  bool get isTicketClosed {
    final s = status.value.trim().toUpperCase();
    return s == 'RESOLVED' || s == 'COMPLETED' || s == 'CLOSED';
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments is Map ? Get.arguments : {};
    ticketId = (args['ticketId'] ?? args['id'] ?? args['chatId'] ?? '').toString();

    if (args['subject'] != null && args['subject'].toString().isNotEmpty) {
      subject.value = args['subject'].toString();
    }
    if (args['status'] != null && args['status'].toString().isNotEmpty) {
      status.value = args['status'].toString();
    }
    if (args['createdAt'] != null && args['createdAt'].toString().isNotEmpty) {
      createdAt.value = args['createdAt'].toString();
    }
    if (args['userId'] != null && args['userId'].toString().isNotEmpty) {
      ticketUserId.value = args['userId'].toString();
    }

    _initDraft();
    _initialize();
  }

  void _initDraft() {
    final draftKey = 'ticket_draft_$ticketId';
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
    ChatDraftService.saveDraft('ticket_draft_$ticketId', messageController.text);
  }

  Future<void> _initialize() async {
    final args = Get.arguments is Map ? Get.arguments : {};
    final String? argUserId = args['userId'];
    if (argUserId != null && argUserId.isNotEmpty) {
      ticketUserId.value = argUserId;
      userService.userId = argUserId;
      debugPrint("✅ SupportTicketDetailController: Set userId from arguments: $argUserId");
    }

    // Try reading cached profile / user info
    try {
      if (userService.userId.isEmpty) {
        await userService.fetchUserId();
      }
    } catch (_) {}

    await fetchTicketDetails();
    setupSocketListeners();
  }

  /// Fetch full ticket details and messages from GET /api/v1/supports/:id
  Future<void> fetchTicketDetails() async {
    if (ticketId.isEmpty) return;

    try {
      isLoading.value = true;
      final response = await _supportService.getSupportDetails(ticketId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        _parseTicketData(data);
      }
    } catch (e) {
      debugPrint("❌ Error fetching support ticket details: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _parseTicketData(dynamic data) {
    if (data != null && data is Map) {
      if (data['subject'] != null && data['subject'].toString().isNotEmpty) {
        subject.value = data['subject'].toString();
      }
      if (data['status'] != null && data['status'].toString().isNotEmpty) {
        status.value = data['status'].toString();
      }
      if (data['createdAt'] != null && data['createdAt'].toString().isNotEmpty) {
        createdAt.value = data['createdAt'].toString();
      }

      // Extract ticket user (owner)
      if (data['user'] != null) {
        if (data['user'] is Map) {
          final uId = data['user']['_id'] ?? data['user']['id'];
          if (uId != null) ticketUserId.value = uId.toString();
          final uName = data['user']['name'] ?? data['user']['fullName'];
          if (uName != null) currentUserName.value = uName.toString();
        } else {
          ticketUserId.value = data['user'].toString();
        }
        if (userService.userId.isEmpty && ticketUserId.value.isNotEmpty) {
          userService.userId = ticketUserId.value;
        }
      }

      final List rawMessages = data['messages'] ?? [];
      final fetchedMessages = rawMessages.map((m) {
        final map = m is Map<String, dynamic>
            ? m
            : Map<String, dynamic>.from(m as Map);
        return SupportMessage.fromJson(map);
      }).toList();

      // Sort messages so newest message is at index 0 for reverse: true ListView
      if (fetchedMessages.length > 1) {
        final firstDate = DateTime.tryParse(fetchedMessages.first.createdAt);
        final lastDate = DateTime.tryParse(fetchedMessages.last.createdAt);
        if (firstDate != null &&
            lastDate != null &&
            firstDate.isBefore(lastDate)) {
          fetchedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
      }

      messages.assignAll(fetchedMessages);
    }
  }

  /// Determines whether a given message was sent by the current user
  bool isMessageFromMe(SupportMessage message) {
    final String myId = userService.userId.trim();
    final String tUserId = ticketUserId.value.trim();
    final String myName = currentUserName.value.trim().toLowerCase();

    final String sId = message.senderId.trim();
    final String sName = message.senderName.trim().toLowerCase();
    final String sRole = message.senderRole.trim().toUpperCase();

    // 1. If explicitly marked with Admin / Support keywords -> NOT ME (Left)
    final bool isAdminName = sName.contains('admin') ||
        sName.contains('support') ||
        sName.contains('agent') ||
        sName.contains('helpdesk');
    final bool isAdminRole = sRole == 'ADMIN' ||
        sRole == 'SUPER_ADMIN' ||
        sRole == 'SUPPORT' ||
        sRole == 'AGENT';

    if (isAdminName || isAdminRole) {
      return false;
    }

    // 2. If sender ID matches user's ID or ticket's owner ID
    if (sId.isNotEmpty) {
      if (myId.isNotEmpty && sId == myId) return true;
      if (tUserId.isNotEmpty && sId == tUserId) return true;
    }

    // 3. If sender name matches current user's name
    if (myName.isNotEmpty && sName.isNotEmpty && sName == myName) {
      return true;
    }

    // 4. If sender role is explicitly USER
    if (sRole == 'USER' || sRole == 'CUSTOMER') {
      return true;
    }

    // 5. In a 1-on-1 support ticket thread, any message that is NOT from Admin/Support is from the User
    if (!isAdminName && !isAdminRole) {
      return true;
    }

    return false;
  }

  /// Listen for real-time socket events for this support ticket: support-message::$ticketId
  void setupSocketListeners() {
    if (ticketId.isEmpty) return;

    final eventName = 'support-message::$ticketId';
    debugPrint('🔄 SupportTicketDetailController: Listening to socket event [$eventName]');

    socketService.on(eventName, _onSocketTicketUpdate);
  }

  void _onSocketTicketUpdate(dynamic data) {
    debugPrint('📥 SupportTicketDetailController: Realtime update on support-message::$ticketId: $data');
    if (data == null) return;

    try {
      dynamic ticketData = data;
      if (data is Map && data.containsKey('data')) {
        ticketData = data['data'];
      }
      _parseTicketData(ticketData);
    } catch (e) {
      debugPrint('❌ Error parsing socket support ticket update: $e');
    }
  }

  /// Pick attachment images
  Future<void> pickAttachments() async {
    if (isTicketClosed) {
      Helpers.showCustomSnackBar("This ticket is resolved and closed for replies.");
      return;
    }
    try {
      final List<File>? picked = await MediaPickerHelper.pickMultiImages(null, 5);
      if (picked != null && picked.isNotEmpty) {
        selectedAttachments.addAll(picked);
        if (selectedAttachments.length > 5) {
          selectedAttachments.removeRange(5, selectedAttachments.length);
        }
      }
    } catch (e) {
      debugPrint("Error picking attachments: $e");
    }
  }

  void removeAttachment(int index) {
    if (index >= 0 && index < selectedAttachments.length) {
      selectedAttachments.removeAt(index);
    }
  }

  /// Send reply message in this support ticket (POST /api/v1/supports/:ticketId/messages)
  Future<void> sendMessage() async {
    if (isTicketClosed) {
      Helpers.showCustomSnackBar("This ticket is resolved and closed for replies.");
      return;
    }

    final text = messageController.text.trim();
    if ((text.isEmpty && selectedAttachments.isEmpty) || ticketId.isEmpty || isSending.value) {
      return;
    }

    final attachmentsToSend = List<File>.from(selectedAttachments);
    messageController.clear();
    selectedAttachments.clear();
    ChatDraftService.clearDraft('ticket_draft_$ticketId');

    try {
      isSending.value = true;
      final response = await _supportService.sendMessage(
        ticketId,
        text,
        attachments: attachmentsToSend,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTicketDetails();
      }
    } catch (e) {
      debugPrint("❌ Error sending support message: $e");
      messageController.text = text;
      selectedAttachments.assignAll(attachmentsToSend);
      ChatDraftService.saveDraft('ticket_draft_$ticketId', text);
      Helpers.showCustomSnackBar("Failed to send message", isError: true);
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    if (ticketId.isNotEmpty) {
      socketService.off('support-message::$ticketId');
    }
    messageController.removeListener(_onMessageChanged);
    ChatDraftService.saveDraft('ticket_draft_$ticketId', messageController.text);
    messageController.dispose();
    super.onClose();
  }
}
