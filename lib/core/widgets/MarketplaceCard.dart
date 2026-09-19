import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import '../../data/models/market_place_model.dart';
import '../../modules/market_place/views/market_place_detail_view.dart';
import 'ContactSellerPopup.dart';

class MarketplaceCard extends StatelessWidget {
  final ItemData item;

  const MarketplaceCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String imagePath = (item.photos != null && item.photos!.isNotEmpty)
        ? item.photos!.first
        : "";
    final String title = item.title ?? "No Title";
    final String? condition = item.condition;
    final String location = item.location?.split(',').first.trim() ?? "Unknown";

    return GestureDetector(
      onTap: () {
        Get.to(() => MarketplaceItemDetailView(item: item));
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
                  child: _buildImage(imagePath),
                ),
                // Floating Condition Badge
                if (condition != null &&
                    condition.trim().isNotEmpty &&
                    condition.trim().toLowerCase() != 'none' &&
                    condition.trim().toLowerCase() != 'null' &&
                    condition.trim().toLowerCase() != 'n/a')
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
                        condition,
                        style: GoogleFonts.inter(
                          color: condition.toLowerCase() == 'new'
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
                  // Title
                  Text(
                    title,
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
                    "\$${item.price ?? 0}",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF9800),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Bottom Action row: Location & Contact
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey.shade500,
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
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
                      ),
                      SizedBox(width: 4.w),

                      // Contact Button
                      GestureDetector(
                        onTap: () {
                          Get.dialog(ContactSellerPopup(item: item));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryColor, const Color(0xFFFF9800)],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                AppIcons.contact_icon,
                                height: 12.sp,
                                width: 12.sp,
                                colorFilter: const ColorFilter.mode(
                                  Colors.black,
                                  BlendMode.srcIn,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "Contact",
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildImage(String imagePath) {
    if (imagePath.isEmpty) {
      return _buildNoImagePlaceholder();
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        height: 115.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildNoImagePlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 115.h,
            width: double.infinity,
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        height: 115.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildNoImagePlaceholder(),
      );
    }
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 115.h,
      width: double.infinity,
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 30.sp,
          ),
          SizedBox(height: 4.h),
          Text(
            "No Image",
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
