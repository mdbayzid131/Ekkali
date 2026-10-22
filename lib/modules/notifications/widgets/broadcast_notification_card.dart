import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/data/models/notifications_model.dart';
import '../views/notification_media_view.dart';

/// Announcement text stays in place; attached media opens in a viewer.
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
          if (imageUrl != null || notification.videoUrl != null)
            Semantics(
              button: true,
              label: notification.videoUrl != null
                  ? 'Play video'
                  : 'View full screen image',
              child: GestureDetector(
                key: const ValueKey('broadcast-media'),
                onTap: () => showDialog<void>(
                  context: context,
                  barrierColor: Colors.black87,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.black,
                    clipBehavior: Clip.antiAlias,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      width: 700,
                      height: MediaQuery.sizeOf(context).height * 0.75,
                      child: NotificationMediaView(
                        title: notification.title,
                        imageUrl: imageUrl,
                        videoUrl: notification.videoUrl,
                      ),
                    ),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (imageUrl == null)
                      const AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ColoredBox(color: Color(0xFF1A1A20)),
                      )
                    else
                      Image.network(
                        imageUrl,
                        key: const ValueKey('broadcast-image'),
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
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
                        errorBuilder: (context, error, stackTrace) =>
                            const AspectRatio(
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
                    if (notification.videoUrl != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                  ],
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
