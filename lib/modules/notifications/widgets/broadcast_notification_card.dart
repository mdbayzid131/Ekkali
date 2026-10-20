import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/data/models/notifications_model.dart';

/// An announcement is read in place, with no link or tap action.
class BroadcastNotificationCard extends StatelessWidget {
  final NotificationItem notification;
  const BroadcastNotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final imageUrl = notification.imageUrl;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: notification.isRead
            ? const Color(0xFF111114)
            : const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: notification.isRead
              ? const Color(0xFF1E1E24)
              : const Color(0xFF2B2B36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl,
              key: const ValueKey('broadcast-image'),
              width: double.infinity,
              fit: BoxFit.fitWidth,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
              errorBuilder: (context, error, stackTrace) => const AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: Color(0xFF1A1A20),
                  child: Center(
                    child: Text(
                      'Image unavailable',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 17.sp,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Padding(
                        padding: EdgeInsets.only(left: 10.w, top: 7.h),
                        child: Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                if (notification.subtitle.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    notification.subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.5,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
