import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/modules/notifications/controllers/notifications_controller.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';
import 'package:moeb_26/core/services/subscription_service.dart';
import 'package:moeb_26/core/widgets/premium_required_dialog.dart';
import 'package:moeb_26/modules/market_place/views/market_place_view.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAccountTap;
  final VoidCallback? onMyJobsTap;
  final VoidCallback? serviceAreaTap;
  final VoidCallback? onMyProductsTap;
  final int notificationCount;
  final String? logoPath;
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final bool showActions;

  CustomAppBar({
    super.key,
    this.onNotificationTap,
    this.onAccountTap,
    this.onMyJobsTap,
    this.serviceAreaTap,
    this.onMyProductsTap,
    this.notificationCount = 0,
    this.logoPath,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.showActions = true,
  });

  final NotificationController _notificationController = Get.put(
    NotificationController(),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20.sp,
                ),
                onPressed: () => Get.back(),
              )
            : null,
        titleSpacing: showBackButton ? 0 : 4.w,
        title: Row(
          children: [
            if (logoPath != null && logoPath!.isNotEmpty) ...[
              Image.asset(logoPath!, height: 70.h, width: 130.w),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null && title!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: CustomText(
                          text: title!,
                          fontSize: 20.sp,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: CustomTextgray(
                          text: subtitle!,
                          fontSize: 12.sp,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: showActions
            ? [
                Obx(
                  () => GestureDetector(
                    onTap:
                        onNotificationTap ??
                        () {
                          Get.toNamed(Routes.notificationsView);
                        },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 30.sp,
                          color: Colors.white,
                        ),
                        if (_notificationController.unreadCount > 0)
                          Positioned(
                            top: -2.w,
                            right: -1.w,
                            child: Container(
                              width: 15.w,
                              height: 15.w,
                              decoration: const BoxDecoration(
                                color: Colors.yellow,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _notificationController.unreadCount > 99
                                      ? '99+'
                                      : '${_notificationController.unreadCount}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                PopupMenuButton<int>(
                  icon: Icon(Icons.menu, size: 30.sp, color: Colors.white),
                  color: const Color(0xFF1E1E1E), // Dark background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: const BorderSide(color: Color(0xFF364153)),
                  ),
                  onSelected: (item) => handleMenuItemSelection(item),
                  itemBuilder: (context) => [
                    PopupMenuItem<int>(
                      value: 7,
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'My Schedule',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_forward,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<int>(
                      value: 3,
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Create Invoice',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_forward,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<int>(
                      value: 6,
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Expense Tracker',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_forward,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<int>(
                      value: 5,
                      child: Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Meet & Greet Sign',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_forward,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<int>(
                      value: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppIcons.marketplace_icon,
                            width: 24.sp,
                            height: 24.sp,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Marketplace',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_forward,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<int>(
                      value: 1,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppIcons.deals_icon,
                            width: 24.sp,
                            height: 24.sp,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Deals',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_forward,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                  offset: const Offset(0, 50),
                ),
              ]
            : null,
      ),
    );
  }

  void handleMenuItemSelection(int item) {
    // Check if user is premium
    bool isPrem = false;
    try {
      isPrem = Get.find<SubscriptionService>().isPremium.value;
    } catch (_) {
      isPrem = false;
    }

    if (!isPrem) {
      PremiumRequiredDialog.show();
      return;
    }

    switch (item) {
      case 3:
        Get.toNamed(Routes.invoiceHistoryView);
        break;
      case 6:
        Get.toNamed(Routes.expenseListView);
        break;
      case 5:
        Get.toNamed(Routes.meetGreetView);
        break;
      case 7:
        Get.toNamed(Routes.myScheduleView);
        break;
      case 4:
        Get.to(() => MarketPlaceView());
        break;
      case 1:
        Get.toNamed(Routes.dealsView);
        break;
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(60.h);
}
