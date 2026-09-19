import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import '../../../core/widgets/Custom_Job_Button.dart';
import '../controllers/market_place_controller.dart';
import '../../../core/widgets/SellItemBottomSheet.dart';
import '../../../core/widgets/MarketplaceCard.dart';

class MarketPlaceView extends StatelessWidget {
  MarketPlaceView({super.key});

  final MarketplaceController controller = Get.find<MarketplaceController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'Marketplace',
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
        onRefresh: () => controller.fetchItems(),
        color: AppColors.primaryColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 10.h),

              // "List Item for Sale" & "My Items" Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomJobButton(
                      text: "List Item",
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 8.w,
                      ),
                      onPressed: () {
                        controller.clearFields();
                        Get.bottomSheet(
                          SellItemBottomSheet(),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomJobButton(
                      text: "My Items",
                      icon: Icons.shopping_bag_outlined,
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 8.w,
                      ),
                      onPressed: () {
                        Get.toNamed(Routes.myItemsView);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 15.h),
              // Search Bar
              TextFormField(
                onChanged: (value) => controller.searchItems(value),
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search accessories...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 14.sp,
                  ),
                  filled: true,
                  fillColor: const Color(0xff1A1A1A),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20.sp,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 16.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xff242424)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xff242424)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xff242424)),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.filteredItems.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  }
                  if (controller.filteredItems.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 50.h),
                          child: Center(
                            child: Text(
                              "No items found",
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: (controller.filteredItems.length / 2).ceil() + 1,
                    itemBuilder: (context, index) {
                      if (index ==
                          (controller.filteredItems.length / 2).ceil()) {
                        return Obx(
                          () => controller.isLoadMore.value
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.h),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                        );
                      }

                      final int leftIndex = index * 2;
                      final int rightIndex = leftIndex + 1;
                      final bool hasRight =
                          rightIndex < controller.filteredItems.length;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 10.h,
                          left: 0,
                          right: 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: MarketplaceCard(
                                item: controller.filteredItems[leftIndex],
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: hasRight
                                  ? MarketplaceCard(
                                      item:
                                          controller.filteredItems[rightIndex],
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
