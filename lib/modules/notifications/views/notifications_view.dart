import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/data/models/Notifications_Model.dart';
import 'package:moeb_26/modules/my_jobs/controllers/my_jobs_controller.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends StatelessWidget {
  NotificationsView({super.key});

  final NotificationController controller =
      Get.isRegistered<NotificationController>()
          ? Get.find<NotificationController>()
          : Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomSubAppBar(title: "Notifications"),
      body: Column(
        children: [
          // Sub-header bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            child: Obx(() {
              final unread = controller.unreadCount;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: unread > 0
                          ? AppColors.primaryColor.withValues(alpha: 0.15)
                          : const Color(0xFF1C1C22),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: unread > 0
                            ? AppColors.primaryColor.withValues(alpha: 0.3)
                            : const Color(0xFF282832),
                      ),
                    ),
                    child: Text(
                      unread > 0 ? "$unread New" : "All caught up",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: unread > 0
                            ? AppColors.primaryColor
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  if (unread > 0)
                    GestureDetector(
                      onTap: () => controller.markAllAsRead(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            color: AppColors.primaryColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "Mark all as read",
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ),

          // Notification Items List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.fetchNotifications();
              },
              color: AppColors.primaryColor,
              backgroundColor: const Color(0xFF1A1A1E),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                if (controller.notifications.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      SizedBox(height: 140.h),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64.w,
                              height: 64.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF131316),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF222228),
                                ),
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: const Color(0xFF64748B),
                                size: 30.sp,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "No notifications yet",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "We'll notify you when important updates arrive.",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 12.5.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 6.h,
                  ),
                  itemCount: controller.notifications.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final notification = controller.notifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Obx(() {
      final currentNoti = controller.notifications.firstWhere(
        (n) => n.id == notification.id,
        orElse: () => notification,
      );

      return Dismissible(
        key: Key(currentNoti.id),
        direction: DismissDirection.endToStart, // Swipe Left to Delete only
        onDismissed: (_) {
          controller.deleteNotification(currentNoti.id);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Delete",
                style: GoogleFonts.inter(
                  color: const Color(0xFFF87171),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.delete_outline_rounded,
                color: const Color(0xFFF87171),
                size: 20.sp,
              ),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: currentNoti.isRead
                ? const Color(0xFF111114)
                : const Color(0xFF16161B),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: currentNoti.isRead
                  ? const Color(0xFF1E1E24)
                  : const Color(0xFF2B2B36),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () => _handleNotificationTap(currentNoti),
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading Icon Container
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F26),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: const Color(0xFF2B2B38),
                        ),
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: SvgPicture.asset(
                        currentNoti.icon,
                        colorFilter: ColorFilter.mode(
                          currentNoti.isRead
                              ? const Color(0xFF94A3B8)
                              : Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentNoti.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5.sp,
                                    fontWeight: currentNoti.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: currentNoti.isRead
                                        ? const Color(0xFFE2E8F0)
                                        : Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!currentNoti.isRead) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  width: 7.w,
                                  height: 7.w,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (currentNoti.subtitle.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              currentNoti.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w400,
                                color: currentNoti.isRead
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12.sp,
                                color: const Color(0xFF64748B),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                currentNoti.timeAgo,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _handleNotificationTap(NotificationItem currentNoti) {
    if (!currentNoti.isRead) {
      controller.markAsRead(currentNoti.id);
    }

    final type = currentNoti.type.toUpperCase();
    final title = currentNoti.title.toLowerCase();
    final subtitle = currentNoti.subtitle.toLowerCase();

    if (type == 'MESSAGE' ||
        title.contains('message') ||
        title.contains('chat') ||
        subtitle.contains('message') ||
        subtitle.contains('chat')) {
      Get.offAllNamed(Routes.bottomNabbarView, arguments: 2);
    } else if (type == 'TASK' ||
        title.contains('job') ||
        subtitle.contains('job') ||
        title.contains('acceptance')) {
      final BookingController bookingController =
          Get.isRegistered<BookingController>()
              ? Get.find<BookingController>()
              : Get.put(BookingController());
      bookingController.isJobAcceptanceView.value = true;
      Get.toNamed(Routes.myJobsView);
    } else if (type == 'REMINDER' ||
        title.contains('deal') ||
        subtitle.contains('deal') ||
        title.contains('offer') ||
        title.contains('saving')) {
      Get.toNamed(Routes.dealsView);
    } else if (title.contains('invoice') ||
        title.contains('payment') ||
        subtitle.contains('invoice') ||
        subtitle.contains('payment')) {
      Get.toNamed(Routes.invoiceHistoryView);
    } else if (title.contains('item') ||
        title.contains('market') ||
        subtitle.contains('item') ||
        subtitle.contains('market')) {
      Get.toNamed(Routes.myItemsView);
    } else {
      Get.toNamed(Routes.bottomNabbarView);
    }
  }
}
