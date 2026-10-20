import 'package:flutter_test/flutter_test.dart';
import 'package:moeb_26/data/models/chat_community_model.dart';

void main() {
  test('group summaries accept string and populated lastMessage values', () {
    final string = CommunityRoom.fromJson({
      '_id': 'a',
      'name': 'A',
      'lastMessage': 'Ok',
    });
    final populated = CommunityRoom.fromJson({
      '_id': 'b',
      'name': 'B',
      'lastMessage': {'text': 'Hi', 'createdAt': '2026-10-20T09:00:00Z'},
    });
    expect(string.lastMessage, 'Ok');
    expect(populated.lastMessage, 'Hi');
    expect(populated.lastMessageAt, '2026-10-20T09:00:00Z');
  });

  test('group metadata update time is not treated as last message time', () {
    final room = CommunityRoom.fromJson({
      '_id': 'a',
      'name': 'A',
      'updatedAt': '2026-10-20T09:00:00Z',
    });
    expect(room.lastMessageAt, isNull);
  });

  test(
    'nested socket envelopes preserve group identity and attachment preview',
    () {
      final payload = CommunityMessage.eventPayload({
        'chatId': 'a',
        'data': {
          'message': {
            '_id': 'm',
            'attachments': ['image.jpg'],
            'sender': 'other',
          },
        },
      });
      expect(payload?['chatId'], 'a');
      expect(CommunityMessage.fromJson(payload!).attachments, ['image.jpg']);
      final group = CommunityRoom.fromJson({
        '_id': 'a',
        'name': 'A',
        'lastMessage': {
          'attachments': ['image.jpg'],
        },
      });
      expect(group.lastMessage, 'Attachment');
    },
  );
}
