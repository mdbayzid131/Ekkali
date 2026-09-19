import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/data/models/market_place_model.dart';
import 'package:moeb_26/core/widgets/ContactSellerPopup.dart';
import 'package:moeb_26/core/widgets/ImagePreviewPopup.dart';
import 'package:moeb_26/core/widgets/SellItemBottomSheet.dart';
import 'package:moeb_26/modules/market_place/controllers/market_place_controller.dart';
import 'package:moeb_26/modules/my_items/controllers/my_items_controller.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';

class MarketplaceItemDetailView extends StatefulWidget {
  final ItemData item;
  final bool isOwnItem;

  const MarketplaceItemDetailView({
    super.key,
    required this.item,
    this.isOwnItem = false,
  });

  @override
  State<MarketplaceItemDetailView> createState() =>
      _MarketplaceItemDetailViewState();
}

class _MarketplaceItemDetailViewState extends State<MarketplaceItemDetailView> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.item.photos ?? [];
    final imageCount = photos.length;
    final String title = widget.item.title ?? "No Title";

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
              'Item Details',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery / Carousel
                  SizedBox(
                    height: 320.h,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        if (imageCount == 0)
                          _buildNoImagePlaceholder()
                        else
                          PageView.builder(
                            controller: _pageController,
                            itemCount: imageCount,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final photoUrl = photos[index];
                              return GestureDetector(
                                onTap: () {
                                  Get.dialog(
                                    ImagePreviewPopup(
                                      imageUrl: photoUrl,
                                      title: title,
                                    ),
                                  );
                                },
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildNoImagePlaceholder(),
                                ),
                              );
                            },
                          ),

                        // Image Index Badge (e.g. 1 / 4)
                        if (imageCount > 1)
                          Positioned(
                            bottom: 16.h,
                            right: 16.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: const Color(0xFF2C2C2C),
                                ),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1} / $imageCount',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // Dot indicators
                        if (imageCount > 1)
                          Positioned(
                            bottom: 16.h,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                imageCount,
                                (index) => Container(
                                  width: 8.w,
                                  height: 8.w,
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? const Color(0xFFFF9800)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Item Details Block
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price tag
                        Text(
                          "\$${widget.item.price ?? 0}",
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF9800),
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Title
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey.shade500,
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              widget.item.location ?? "No location",
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade400,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),
                        const Divider(color: Color(0xFF1E1E1E), height: 1),
                        SizedBox(height: 16.h),

                        // Specs Row (Condition / Status)
                        Wrap(
                          spacing: 10.w,
                          runSpacing: 8.h,
                          children: [
                            if (widget.item.condition != null &&
                                widget.item.condition!.trim().isNotEmpty &&
                                widget.item.condition!.trim().toLowerCase() != 'none' &&
                                widget.item.condition!.trim().toLowerCase() != 'null' &&
                                widget.item.condition!.trim().toLowerCase() != 'n/a')
                              _buildBadge(
                                label: "Condition: ${widget.item.condition}",
                                backgroundColor: const Color(0xFF1F1C1C),
                                textColor: const Color(0xFFD5C4AB),
                              ),
                            if (widget.item.status != null)
                              _buildBadge(
                                label: widget.item.status!.toUpperCase(),
                                backgroundColor:
                                    widget.item.status!.toUpperCase() == 'SOLD'
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : Colors.green.withValues(alpha: 0.15),
                                textColor:
                                    widget.item.status!.toUpperCase() == 'SOLD'
                                    ? Colors.redAccent
                                    : Colors.green,
                              ),
                          ],
                        ),

                        SizedBox(height: 16.h),
                        const Divider(color: Color(0xFF1E1E1E), height: 1),
                        SizedBox(height: 16.h),

                        // Description Section
                        Text(
                          "Description",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          widget.item.description ?? "No description provided.",
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontSize: 14.sp,
                            height: 1.5,
                          ),
                        ),

                        if (!widget.isOwnItem) ...[
                          SizedBox(height: 24.h),
                          const Divider(color: Color(0xFF1E1E1E), height: 1),
                          SizedBox(height: 20.h),

                          // Seller Profile Section
                          Text(
                            "Seller Information",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              final seller = widget.item.createdBy;
                              if (seller != null &&
                                  (seller.id?.isNotEmpty ?? false)) {
                                final preferredController =
                                    Get.isRegistered<
                                      PreferredDriversController
                                    >()
                                    ? Get.find<PreferredDriversController>()
                                    : Get.put(PreferredDriversController());

                                preferredController.openChauffeurProfile(
                                  userId: seller.id!,
                                  name: seller.name ?? "Seller",
                                  imageUrl: seller.profilePicture ?? "",
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color(0xFF242424),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24.r,
                                    backgroundImage:
                                        (widget
                                                    .item
                                                    .createdBy
                                                    ?.profilePicture !=
                                                null &&
                                            widget
                                                .item
                                                .createdBy!
                                                .profilePicture!
                                                .isNotEmpty)
                                        ? NetworkImage(
                                            widget
                                                .item
                                                .createdBy!
                                                .profilePicture!,
                                          )
                                        : null,
                                    backgroundColor: const Color(0xFF27272A),
                                    child:
                                        (widget
                                                    .item
                                                    .createdBy
                                                    ?.profilePicture ==
                                                null ||
                                            widget
                                                .item
                                                .createdBy!
                                                .profilePicture!
                                                .isEmpty)
                                        ? Text(
                                            widget.item.createdBy?.name
                                                    ?.substring(0, 1)
                                                    .toUpperCase() ??
                                                "S",
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 14.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.item.createdBy?.name ??
                                              "Unknown Seller",
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (widget.item.createdBy?.email !=
                                            null) ...[
                                          SizedBox(height: 4.h),
                                          Text(
                                            widget.item.createdBy!.email!,
                                            style: GoogleFonts.inter(
                                              color: Colors.grey.shade500,
                                              fontSize: 13.sp,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
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

          // Bottom Fixed Action Panel
          Container(
            padding: EdgeInsets.fromLTRB(
              20.w,
              16.h,
              20.w,
              MediaQuery.of(context).padding.bottom + 16.h,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0C0C0C),
              border: Border(
                top: BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
              ),
            ),
            child: widget.isOwnItem
                ? (widget.item.status?.toUpperCase() != 'SOLD'
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomButton(
                              onPressed: () async {
                                final MyItemsController controller;
                                if (Get.isRegistered<MyItemsController>()) {
                                  controller = Get.find<MyItemsController>();
                                } else {
                                  controller = Get.put(MyItemsController());
                                }
                                await controller.markAsSold(
                                  widget.item.id ?? '',
                                );
                                setState(() {
                                  widget.item.status = 'SOLD';
                                });
                              },
                              text: "Mark as Sold",
                              backgroundColor: const Color(0xFF22C55E),
                              textColor: Colors.black,
                              icon: Icon(
                                Icons.check_circle_outline,
                                size: 18.sp,
                                color: Colors.black,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    onPressed: () {
                                      final MarketplaceController mpc;
                                      if (Get.isRegistered<
                                        MarketplaceController
                                      >()) {
                                        mpc = Get.find<MarketplaceController>();
                                      } else {
                                        mpc = Get.put(MarketplaceController());
                                      }
                                      mpc.prefillForEdit(
                                        widget.item.title ?? '',
                                        widget.item.price?.toString() ?? '0',
                                        widget.item.location ?? '',
                                        widget.item.condition ?? '',
                                        widget.item.description ?? '',
                                        widget.item.photos ?? [],
                                      );
                                      Get.bottomSheet(
                                        SellItemBottomSheet(
                                          editItemId: widget.item.id,
                                        ),
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                      );
                                    },
                                    text: "Edit Item",
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 18.sp,
                                      color: Colors.black,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14.h,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: CustomButton(
                                    onPressed: () => _showDeleteDialog(context),
                                    text: "Delete",
                                    textColor: Colors.redAccent,
                                    backgroundColor: const Color(0xFF1E1E1E),
                                    borderColor: const Color(0xFF2E2E2E),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18.sp,
                                      color: Colors.redAccent,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14.h,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: () {
                                  final MarketplaceController mpc;
                                  if (Get.isRegistered<
                                    MarketplaceController
                                  >()) {
                                    mpc = Get.find<MarketplaceController>();
                                  } else {
                                    mpc = Get.put(MarketplaceController());
                                  }
                                  mpc.prefillForEdit(
                                    widget.item.title ?? '',
                                    widget.item.price?.toString() ?? '0',
                                    widget.item.location ?? '',
                                    widget.item.condition ?? '',
                                    widget.item.description ?? '',
                                    widget.item.photos ?? [],
                                  );
                                  Get.bottomSheet(
                                    SellItemBottomSheet(
                                      editItemId: widget.item.id,
                                    ),
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                  );
                                },
                                text: "Edit Item",
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18.sp,
                                  color: Colors.black,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomButton(
                                onPressed: () => _showDeleteDialog(context),
                                text: "Delete",
                                textColor: Colors.redAccent,
                                backgroundColor: const Color(0xFF1E1E1E),
                                borderColor: const Color(0xFF2E2E2E),
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18.sp,
                                  color: Colors.redAccent,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                              ),
                            ),
                          ],
                        ))
                : Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          onPressed: () {
                            Get.dialog(ContactSellerPopup(item: widget.item));
                          },
                          text: "Contact Seller",
                          icon: SvgPicture.asset(
                            AppIcons.contact_icon,
                            height: 18.sp,
                            width: 18.sp,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
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
              if (Get.isRegistered<MyItemsController>()) {
                final MyItemsController controller =
                    Get.find<MyItemsController>();
                controller.deleteItem(widget.item.id ?? '');
              }
              Get.back(); // close dialog
              Get.back(); // pop detailed view page
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

  Widget _buildBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      color: Colors.grey[900],
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 40.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            "No Image Available",
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
