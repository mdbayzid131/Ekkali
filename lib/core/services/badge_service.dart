import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

class BadgeService {
  /// Updates the launcher app icon badge count
  static Future<void> updateBadgeCount(int count) async {
    try {
      final isSupported = await AppBadgePlus.isSupported();
      if (isSupported) {
        if (count > 0) {
          await AppBadgePlus.updateBadge(count);
          debugPrint('🏷️ App icon badge updated to: $count');
        } else {
          await AppBadgePlus.updateBadge(0);
          debugPrint('🏷️ App icon badge cleared');
        }
      } else {
        debugPrint('ℹ️ App icon badge is not supported on this launcher/device');
      }
    } catch (e) {
      debugPrint('⚠️ Error updating app icon badge: $e');
    }
  }

  /// Clears the app icon badge
  static Future<void> clearBadge() async {
    await updateBadgeCount(0);
  }
}
