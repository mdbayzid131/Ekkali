import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import '../../data/models/my_items_model.dart';
import '../../modules/my_items/controllers/my_items_controller.dart';
import '../../modules/market_place/views/market_place_detail_view.dart';
import 'SellItemBottomSheet.dart';
import '../../modules/market_place/controllers/market_place_controller.dart';

class MyItemsCard extends StatelessWidget {
  final MyItemsModel item;

  const MyItemsCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String location = item.location.split(',').first.trim();
    final bool isSold = item.status.toUpperCase() == 'SOLD';

    return GestureDetector(
      onTap: () {
        Get.to(
          () => MarketplaceItemDetailView(
            item: item.toItemData(),
            isOwnItem: true,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFF111113),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFF222226), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Stack with Overlay Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(15.r),
                  ),
                  child: _buildImage(),
                ),
                // Floating Condition Badge
                if (item.condition.trim().isNotEmpty &&
                    item.condition.trim().toLowerCase() != 'none' &&
                    item.condition.trim().toLowerCase() != 'null' &&
                    item.condition.trim().toLowerCase() != 'n/a')
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFF2C2C2C)),
                      ),
                      child: Text(
                        item.condition,
                        style: GoogleFonts.inter(
                          color: item.condition.toLowerCase() == 'new'
                              ? Colors.green.shade400
                              : const Color(0xFFFF9800),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Info Section
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Name
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Price
                  Text(
                    "\$${item.price}",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF9800),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Location row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey.shade500,
                        size: 13.sp,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),

                  // Status + Options row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Pill
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSold
                                ? const Color(0xFF2A1C1C)
                                : const Color(0xFF1E1E22),
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(
                              color: isSold
                                  ? const Color(0xFF4A2828)
                                  : const Color(0xFF2D2D33),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSold ? Colors.red : Colors.green,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSold ? Colors.red : Colors.green)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                isSold ? "Sold" : "Available",
                                style: GoogleFonts.inter(
                                  color: isSold ? Colors.red.shade300 : Colors.white70,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Options Trigger
                      GestureDetector(
                        onTap: () => _showOptionsDialog(context),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 18.sp,
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
    );
  }

  void _showOptionsDialog(BuildContext context) {
    final bool isSold = item.status.toUpperCase() == 'SOLD';

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSold) ...[
              // Mark as Sold Button
              TextButton(
                onPressed: () {
                  Get.back();
                  final MyItemsController controller =
                      Get.find<MyItemsController>();
                  controller.markAsSold(item.id);
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: const Color(0xFF22C55E),
                      size: 20.sp,
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      "Mark as Sold",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: const Color(0xFF2E2E2E), height: 16.h),
              // Edit Button
              TextButton(
                onPressed: () {
                  Get.back();
                  final MarketplaceController mpc;
                  if (Get.isRegistered<MarketplaceController>()) {
                    mpc = Get.find<MarketplaceController>();
                  } else {
                    mpc = Get.put(MarketplaceController());
                  }
                  mpc.prefillForEdit(
                    item.name,
                    item.price.toString(),
                    item.location,
                    item.condition,
                    item.description,
                    item.photos,
                  );
                  Get.bottomSheet(
                    SellItemBottomSheet(editItemId: item.id),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                },
                child: Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.edit_icon_myjob,
                      height: 18.sp,
                      width: 18.sp,
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      "Edit",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: const Color(0xFF2E2E2E), height: 16.h),
            ],
            // Delete Button
            TextButton(
              onPressed: () {
                Get.back();
                _showDeleteDialog(context);
              },
              child: Row(
                children: [
                  SvgPicture.asset(
                    AppIcons.deletemyjob_icon,
                    height: 18.sp,
                    width: 18.sp,
                  ),
                  SizedBox(width: 14.w),
                  Text(
                    "Delete",
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.imagePath.isEmpty) {
      return Container(
        height: 115.h,
        width: double.infinity,
        color: Colors.grey[900],
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 40.sp,
        ),
      );
    }

    return Image.network(
      item.imagePath,
      height: 115.h,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 115.h,
        width: double.infinity,
        color: Colors.grey[900],
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 40.sp,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          "Delete Item",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this item? This action cannot be undone.",
          style: GoogleFonts.inter(color: const Color(0xff949494)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              final MyItemsController controller =
                  Get.find<MyItemsController>();
              controller.deleteItem(item.id);
              Get.back();
            },
            child: Text(
              "Delete",
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
