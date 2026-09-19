import 'dart:io';
import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/data/models/chat_message_model.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/data/models/chat_model.dart';

class SocketRepository {
  final ApiClient apiClient;

  SocketRepository({required this.apiClient});

  /// Get list of chats
  Future<List<ChatPreview>> getChats() async {
    try {
      final response = await apiClient.getData(ApiConstants.chats);
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => ChatPreview.fromJson(json)).toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Get single chat by ID
  Future<ChatPreview?> getChatById(String chatId) async {
    try {
      final url = '${ApiConstants.chats}/$chatId';
      final response = await apiClient.getData(url);
      if (response.statusCode == 200 && response.data != null) {
        return ChatPreview.fromJson(response.data['data']);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Create chat with a participant (optionally for a job)
  Future<ChatPreview?> createChat(String participantId, [String? jobId]) async {
    try {
      final Map<String, dynamic> body = {
        'participantId': participantId,
      };
      if (jobId != null && jobId.trim().isNotEmpty) {
        body['jobId'] = jobId.trim();
      }

      final response = await apiClient.postData(ApiConstants.chats, body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['data'] != null) {
          return ChatPreview.fromJson(response.data['data']);
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        if (e.response?.data != null && e.response?.data['data'] != null) {
          try {
            return ChatPreview.fromJson(e.response!.data['data']);
          } catch (_) {}
        }
        // Chat already exists, fetch the chat list to find it
        final chats = await getChats();
        try {
          if (jobId != null && jobId.trim().isNotEmpty) {
            return chats.firstWhere(
              (chat) =>
                  chat.participants.any((p) => p.id == participantId) &&
                  chat.jobId == jobId,
              orElse: () => chats.firstWhere(
                (chat) => chat.participants.any((p) => p.id == participantId),
              ),
            );
          } else {
            return chats.firstWhere(
              (chat) => chat.participants.any((p) => p.id == participantId),
            );
          }
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Create or get chat with a participant for an item
  Future<ChatPreview?> contactSeller(
    String participantId,
    String itemId,
  ) async {
    try {
      final response = await apiClient.postData(ApiConstants.chats, {
        'participantId': participantId,
        'itemId': itemId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['data'] != null) {
          return ChatPreview.fromJson(response.data['data']);
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Chat already exists, fetch the chat list to find it
        final chats = await getChats();
        try {
          return chats.firstWhere(
            (chat) =>
                chat.participants.any((p) => p.id == participantId) &&
                chat.item?.id == itemId,
            orElse: () => chats.firstWhere(
              (chat) => chat.participants.any((p) => p.id == participantId),
            ),
          );
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Get message history raw response for a chat (cursor pagination)
  Future<Response> getMessagesRaw(
    String chatId, {
    String? cursor,
    int limit = 40,
  }) async {
    final url = '/messages/$chatId';
    final query = <String, dynamic>{
      'limit': limit,
      'sort': '-createdAt',
    };
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }
    return await apiClient.getData(url, query: query);
  }

  /// Get message history for a chat
  Future<List<ChatMessage>> getMessages(
    String chatId, {
    int page = 1,
    int limit = 40,
    String? cursor,
  }) async {
    try {
      final response = await getMessagesRaw(chatId, cursor: cursor, limit: limit);
      if (response.statusCode == 200 && response.data != null) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Send a message
  Future<ChatMessage?> sendMessage(
    String chatId,
    String text, {
    List<File>? attachments,
    String? replyTo,
  }) async {
    try {
      final url = '/messages/$chatId';
      Response response;
      if (attachments != null && attachments.isNotEmpty) {
        final formData = FormData();
        if (text.isNotEmpty) {
          formData.fields.add(MapEntry('text', text));
        }
        if (replyTo != null && replyTo.isNotEmpty) {
          formData.fields.add(MapEntry('replyTo', replyTo));
        }
        for (var file in attachments) {
          formData.files.add(
            MapEntry(
              'attachments',
              await MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              ),
            ),
          );
        }
        response = await apiClient.postData(url, formData);
      } else {
        final body = <String, dynamic>{'text': text};
        if (replyTo != null && replyTo.isNotEmpty) {
          body['replyTo'] = replyTo;
        }
        response = await apiClient.postData(url, body);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['data'] != null) {
          return ChatMessage.fromJson(response.data['data']);
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Delete a chat
  Future<Response> deleteChat(String chatId) async {
    try {
      final url = '${ApiConstants.chats}/$chatId';
      final response = await apiClient.deleteData(url);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
