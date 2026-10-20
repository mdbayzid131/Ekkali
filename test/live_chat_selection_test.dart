import 'package:moeb_26/data/models/chat_message_model.dart';
// Test doubles intentionally skip production initialization and network setup.
// ignore_for_file: must_call_super

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moeb_26/core/services/chat_draft_service.dart';
import 'package:moeb_26/core/services/community_service.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/modules/chat/controllers/chat_controller.dart';
import 'package:moeb_26/modules/chat_community/controllers/chat_community_detail_controller.dart';

class _User extends UserService {
  @override
  void onInit() {}
}

class _Socket extends SocketService {
  final joined = <String>[];
  @override
  void onInit() {}
  @override
  void onClose() {}
  @override
  void joinChat(String chatId) {
    joined.add(chatId);
    activeChatId = chatId;
  }

  @override
  void leaveChat(String chatId) {
    activeChatId = null;
  }
}

class _Repo implements SocketRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Response response(dynamic data) => Response(
  requestOptions: RequestOptions(path: '/test'),
  statusCode: 200,
  data: {'data': data},
);

Map<String, dynamic> message(String groupId, String text, String time) => {
  '_id': '$groupId-$text',
  'chatId': groupId,
  'sender': 'me',
  'text': text,
  'createdAt': time,
};

class _Community extends CommunityService {
  final requested = <String>[];
  final pending = <String, Completer<Response>>{};
  Completer<Response>? sendResponse;
  Completer<Response>? groupsResponse;
  String? sentGroup;
  @override
  void onInit() {}
  @override
  Future<Response> getChatGroups() async =>
      groupsResponse?.future ??
      response([
        {
          '_id': 'a',
          'name': 'A',
          'lastMessage': 'Ok',
          'lastMessageAt': '2026-10-20T09:00:03Z',
        },
        {
          '_id': 'b',
          'name': 'B',
          'lastMessage': 'Hi',
          'lastMessageAt': '2026-10-19T11:45:28Z',
        },
      ]);
  @override
  Future<Response> getGroupMessages(
    String chatId, {
    int? page,
    int limit = 50,
    String? cursor,
  }) {
    requested.add(chatId);
    return pending[chatId]?.future ?? Future.value(response(<dynamic>[]));
  }

  @override
  Future<Response> sendGroupMessage(
    String chatId, {
    required String text,
    List<File>? attachments,
    String? replyTo,
  }) {
    sentGroup = chatId;
    return sendResponse!.future;
  }
}

class _Chat extends ChatController {
  @override
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late _Community service;
  late _Socket socket;
  late ChatController chat;

  setUp(() async {
    Get.testMode = true;
    await StorageService.clearAll();
    ChatDraftService.drafts.clear();
    Get.put<UserService>(_User()..userId = 'me');
    socket = _Socket();
    Get.put<SocketService>(socket);
    service = _Community();
    Get.put<CommunityService>(service);
    Get.put<SocketRepository>(_Repo());
    chat = Get.put<ChatController>(_Chat());
  });
  tearDown(() async {
    Get.reset();
  });

  test(
    'nested community messages update unread once across both streams',
    () async {
      await chat.fetchChatGroups();
      chat.setupRealtimeUpdates();
      final data = message('a', 'new message', '2026-10-21T12:00:00Z')
        ..['sender'] = 'other';
      socket.lastReceivedCommunityMessage.value = {
        'chatId': 'a',
        'data': {'message': data},
      };
      socket.lastReceivedMessage.value = ChatMessage.fromJson(data);
      expect(chat.communityRoom.value?.lastMessage, 'new message');
      expect(chat.communityRoom.value?.unreadCount, 1);
      expect(chat.unreadUsersCount, 1);
    },
  );

  testWidgets(
    'detail receives nested payload and keeps live arrivals during history fetch',
    (tester) async {
      await chat.fetchChatGroups();
      final detail = Get.put(CommunityChatDetailController());
      await tester.pump();
      service.pending['a'] = Completer<Response>();
      final fetch = detail.fetchMessages();
      socket.lastReceivedCommunityMessage.value = {
        'chatId': 'a',
        'data': {'message': message('a', 'live', '2026-10-21T12:00:00Z')},
      };
      service.pending['a']!.complete(
        response([message('a', 'history', '2026-10-20T12:00:00Z')]),
      );
      await fetch;
      expect(detail.messages.map((m) => m.text), ['live', 'history']);
      expect(chat.communityRoom.value?.lastMessage, 'live');
      await Get.delete<CommunityChatDetailController>();
      await tester.pump();
    },
  );

  testWidgets(
    'closing detail before groups load never joins or fetches a room',
    (tester) async {
      service.groupsResponse = Completer<Response>();
      Get.put(CommunityChatDetailController());
      await Get.delete<CommunityChatDetailController>();
      service.groupsResponse!.complete(
        response([
          {'_id': 'a', 'name': 'A'},
        ]),
      );
      await tester.pump();
      expect(socket.joined, isEmpty);
      expect(service.requested, isEmpty);
    },
  );

  test(
    'late group summary preserves a newer socket preview and selection',
    () async {
      await chat.fetchChatGroups();
      chat.setupRealtimeUpdates();
      service.groupsResponse = Completer<Response>();
      final fetch = chat.fetchChatGroups();
      chat.selectGroup(chat.chatGroups.firstWhere((g) => g.id == 'b'));
      socket.lastReceivedCommunityMessage.value = message(
        'b',
        'live B',
        '2026-10-21T12:00:00Z',
      );
      service.groupsResponse!.complete(
        response([
          {'_id': 'a', 'name': 'A', 'lastMessage': 'old A'},
          {'_id': 'b', 'name': 'B', 'lastMessage': 'old B'},
        ]),
      );
      await fetch;
      expect(chat.communityRoom.value?.id, 'b');
      expect(chat.communityRoom.value?.lastMessage, 'live B');
    },
  );

  test(
    'restores saved group with its own API preview after reopening',
    () async {
      await StorageService.setString('selected_chat_group_id', 'b');
      await chat.fetchChatGroups();
      expect(chat.communityRoom.value?.id, 'b');
      expect(chat.communityRoom.value?.lastMessage, 'Hi');
      chat.selectGroup(chat.chatGroups.first);
      await Future<void>.delayed(Duration.zero);
      final reopened = _Chat();
      await reopened.fetchChatGroups();
      expect(reopened.communityRoom.value?.id, 'a');
      expect(reopened.communityRoom.value?.lastMessage, 'Ok');
      expect(service.requested, isEmpty);
    },
  );

  testWidgets('detail restores saved group and fetches messages only once', (
    tester,
  ) async {
    await StorageService.setString('selected_chat_group_id', 'b');
    await chat.fetchChatGroups();
    final detail = Get.put(CommunityChatDetailController());
    await tester.pump();
    expect(detail.room.id, 'b');
    expect(service.requested, ['b']);
    expect(socket.joined, ['b']);
    await Get.delete<CommunityChatDetailController>();
    await tester.pump();
  });

  testWidgets(
    'late response and draft from old group cannot replace selected group',
    (tester) async {
      await chat.fetchChatGroups();
      final detail = Get.put(CommunityChatDetailController());
      await tester.pump();
      final a = Completer<Response>();
      final b = Completer<Response>();
      service.pending.addAll({'a': a, 'b': b});
      final oldFetch = detail.fetchMessages();
      detail.messageController.text = 'draft for A';
      detail.changeGroup(chat.chatGroups.last);
      b.complete(response([message('b', 'new B', '2026-10-21T12:00:00Z')]));
      await tester.pump();
      a.complete(response([message('a', 'late A', '2026-10-21T11:00:00Z')]));
      await oldFetch;
      await tester.pump();
      expect(detail.messages.single.text, 'new B');
      expect(detail.messageController.text, isEmpty);
      expect(await StorageService.getString('selected_chat_group_id'), 'b');
      expect(ChatDraftService.getDraft('community_a'), 'draft for A');
      expect(chat.communityRoom.value?.lastMessage, 'new B');
      await Get.delete<CommunityChatDetailController>();
      await tester.pump();
    },
  );

  test(
    'older or unscoped socket message cannot overwrite selected preview',
    () async {
      await chat.fetchChatGroups();
      chat.setupRealtimeUpdates();
      chat.updateGroupLastMessage('a', 'old', '2026-10-19T00:00:00Z');
      socket.lastReceivedCommunityMessage.value = {'text': 'wrong group'};
      expect(chat.communityRoom.value?.lastMessage, 'Ok');
      socket.lastReceivedCommunityMessage.value = {
        'chatId': 'b',
        'text': 'other group',
        'createdAt': '2026-10-21T00:00:00Z',
      };
      expect(chat.communityRoom.value?.lastMessage, 'Ok');
      chat.selectGroup(chat.chatGroups.firstWhere((g) => g.id == 'b'));
      expect(chat.communityRoom.value?.lastMessage, 'other group');
    },
  );

  testWidgets(
    'send completion stays with original group after dropdown switch',
    (tester) async {
      await chat.fetchChatGroups();
      final detail = Get.put(CommunityChatDetailController());
      await tester.pump();
      service.sendResponse = Completer<Response>();
      detail.messageController.text = 'sent to A';
      final sending = detail.sendMessage();
      detail.changeGroup(chat.chatGroups.last);
      await tester.pump();
      service.sendResponse!.complete(
        response(message('a', 'sent to A', '2026-10-21T13:00:00Z')),
      );
      await sending;
      expect(service.sentGroup, 'a');
      expect(detail.room.id, 'b');
      expect(detail.messages, isEmpty);
      expect(chat.communityRoom.value?.lastMessage, 'Hi');
      expect(chat.chatGroups.first.lastMessage, 'sent to A');
      await Get.delete<CommunityChatDetailController>();
      await tester.pump();
    },
  );
}
