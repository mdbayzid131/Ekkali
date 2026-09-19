import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import '../controllers/my_items_controller.dart';
import '../../../core/widgets/my_items_card.dart';

class MyItemsView extends StatelessWidget {
  MyItemsView({super.key});

  final MyItemsController controller = Get.find<MyItemsController>();

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
              'My Items',
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
        onRefresh: () => controller.fetchMyItems(),
        color: AppColors.primaryColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 15.h),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.myItems.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  }

                  if (controller.myItems.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 200.h),
                        Center(
                          child: Text(
                            "No items found",
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: (controller.myItems.length / 2).ceil() + 1,
                    itemBuilder: (context, index) {
                      if (index == (controller.myItems.length / 2).ceil()) {
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
                          rightIndex < controller.myItems.length;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: MyItemsCard(
                                item: controller.myItems[leftIndex],
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: hasRight
                                  ? MyItemsCard(
                                      item: controller.myItems[rightIndex],
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
