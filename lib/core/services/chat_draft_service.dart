import 'package:get/get.dart';
import 'package:moeb_26/core/services/storege_service.dart';

class ChatDraftService {
  // In-memory reactive cache for instant synchronous retrieval
  static final RxMap<String, String> drafts = <String, String>{}.obs;

  /// Synchronously gets the draft from in-memory cache
  static String getDraft(String key) {
    return drafts[key] ?? '';
  }

  /// Asynchronously loads the draft from persistent storage
  static Future<String> loadDraft(String key) async {
    if (drafts.containsKey(key) && drafts[key]!.isNotEmpty) {
      return drafts[key]!;
    }
    try {
      final saved = await StorageService.getString('chat_draft_$key');
      if (saved.isNotEmpty) {
        drafts[key] = saved;
        return saved;
      }
    } catch (_) {}
    return '';
  }

  /// Saves the draft to both in-memory cache and persistent storage
  static void saveDraft(String key, String text) {
    if (text.trim().isEmpty) {
      clearDraft(key);
    } else {
      drafts[key] = text;
      StorageService.setString('chat_draft_$key', text);
    }
  }

  /// Clears the draft from both in-memory cache and persistent storage
  static void clearDraft(String key) {
    drafts.remove(key);
    StorageService.remove('chat_draft_$key');
  }
}
