import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/data/models/ratings_feedback_model.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';
import '../controllers/ratings_feedback_controller.dart';

class RatingsFeedbackView extends StatelessWidget {
  RatingsFeedbackView({super.key});

  final RatingsFeedbackController controller = Get.put(
    RatingsFeedbackController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20.sp,
              ),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Ratings & Feedback',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () => controller.fetchReviews(),
        child: Obx(() {
          if (controller.isLoading.value && controller.reviews.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              SizedBox(height: 6.h),

              // Executive Rating Summary Card
              _buildSummaryHeader(),

              // Feedback List
              if (controller.reviews.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 80.h),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48.sp,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "No reviews yet",
                          style: GoogleFonts.inter(
                            color: const Color(0xFFA1A1A1),
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: controller.reviews.length,
                  itemBuilder: (context, index) {
                    final item = controller.reviews[index];
                    return _buildFeedbackCard(item);
                  },
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Executive Summary Header Card
  Widget _buildSummaryHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFF26262E), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side: Big Score Number & Stars
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    controller.averageRating.value > 0
                        ? controller.averageRating.value.toStringAsFixed(1)
                        : "5.0",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    "/ 5.0",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8E8E93),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final avg = controller.averageRating.value > 0
                      ? controller.averageRating.value
                      : 5.0;
                  return Icon(
                    starValue <= avg
                        ? Icons.star_rounded
                        : (starValue - 0.5 <= avg
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded),
                    color: const Color(0xFFFEDB9B),
                    size: 18.sp,
                  );
                }),
              ),
            ],
          ),

          const Spacer(),
          Container(
            width: 1,
            height: 44.h,
            color: const Color(0xFF26262E),
          ),
          const Spacer(),

          // Right side: Total count & verified badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: const Color(0xFF22C55E),
                      size: 12.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "Verified",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF22C55E),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "${controller.totalReviews.value} Total Reviews",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Modern Feedback Card Widget
  Widget _buildFeedbackCard(Review item) {
    String dateFormatted = "";
    try {
      dateFormatted = DateFormat("dd MMM, yyyy").format(item.createdAt);
    } catch (_) {
      dateFormatted = "";
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF222228), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Reviewer Info + Date + Rating Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Clickable Reviewer Avatar & Name
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openReviewerProfile(item),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 38.r,
                        height: 38.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2E2E38),
                            width: 1.0,
                          ),
                        ),
                        child: ClipOval(
                          child: item.reviewerImage.isNotEmpty &&
                                  item.reviewerImage.startsWith('http')
                              ? Image.network(
                                  item.reviewerImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildAvatarFallback(item.reviewerName),
                                )
                              : _buildAvatarFallback(item.reviewerName),
                        ),
                      ),
                      SizedBox(width: 10.w),

                      // Reviewer Name & Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    item.reviewerName,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white38,
                                  size: 11.sp,
                                ),
                              ],
                            ),
                            if (dateFormatted.isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Text(
                                dateFormatted,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF8E8E93),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Rating Stars Badge in top right
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFF2E2E38)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: const Color(0xFFFEDB9B),
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "${item.rating}.0",
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFEDB9B),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Feedback Text
          Text(
            item.comment,
            style: GoogleFonts.inter(
              color: const Color(0xFFD4D4D8),
              fontSize: 13.sp,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _openReviewerProfile(Review item) {
    if (item.reviewerId.isEmpty) return;

    final PreferredDriversController preferredController;
    if (Get.isRegistered<PreferredDriversController>()) {
      preferredController = Get.find<PreferredDriversController>();
    } else {
      preferredController = Get.put(PreferredDriversController());
    }

    final placeholderChauffeur = FavoriteChauffeur(
      id: item.reviewerId,
      name: item.reviewerName,
      imageUrl: item.reviewerImage,
      rating: item.rating.toDouble(),
      companyName: '',
      ratingCount: '',
      serviceArea: '',
    );
    preferredController.viewProfile(placeholderChauffeur);
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "U";
    return Container(
      color: const Color(0xFF24242A),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          color: const Color(0xFFFEDB9B),
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
