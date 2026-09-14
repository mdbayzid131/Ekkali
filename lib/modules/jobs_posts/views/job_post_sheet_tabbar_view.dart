import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'by_the_hour_view.dart';
import '../controllers/job_post_controller.dart';
import 'one_way_view.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';

class JobPostSheetTabBarView extends StatelessWidget {
  const JobPostSheetTabBarView({super.key});

  @override
  Widget build(BuildContext context) {
    final PostJobController controller = Get.find<PostJobController>();

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
              'Post New Job',
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
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _buildTabBar(controller),
            SizedBox(height: 16.h),
            Expanded(
              child: Obx(
                () => controller.jobType.value == 'One Way'
                    ? OnewayScreen()
                    : ByTheHour(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildChauffeurSelection(
    BuildContext context,
    PostJobController controller,
  ) {
    return Container(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chauffeur Selection',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color.fromARGB(255, 255, 255, 255), // warm beige
            ),
          ),
          SizedBox(height: 8.h),
          Obx(
            () => GestureDetector(
              onTap: () =>
                  showChauffeurSelectionBottomSheet(context, controller),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1C1C), // dark background
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFF364153)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        controller.chauffeurSelectionText,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showChauffeurSelectionBottomSheet(
    BuildContext context,
    PostJobController controller, {
    VoidCallback? onDone,
  }) {
    // Refresh favorite drivers & service areas to ensure latest data from backend
    controller.fetchFavoriteDrivers();
    controller.fetchServiceAreas();

    final activeTab =
        (controller.chauffeurSelectionType.value == 'favorites' ? 1 : 0).obs;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: const Border(
            top: BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Top Navigation Bar with Close (Cross) Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chauffeur Selection',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Tab Bar Switcher for "Service Area" and "Favorite Chauffeur"
            Obx(
              () => Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1C1C),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFF364153)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          activeTab.value = 0;
                          controller.fetchServiceAreas();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: activeTab.value == 0
                                ? AppColors.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              'Service Area',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: activeTab.value == 0
                                    ? Colors.black
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          activeTab.value = 1;
                          controller.fetchFavoriteDrivers();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: activeTab.value == 1
                                ? AppColors.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              'Favorite Chauffeur',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: activeTab.value == 1
                                    ? Colors.black
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Tab Content Body
            Expanded(
              child: SingleChildScrollView(
                child: Obx(
                  () => activeTab.value == 0
                      ? _buildServiceAreaTab(context, controller)
                      : _buildFavoriteChauffeurTab(context, controller),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Done Button
            CustomButton(
              text: 'Done',
              onPressed: () {
                Get.back();
                if (onDone != null) {
                  onDone();
                }
              },
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  static Widget _buildServiceAreaTab(
    BuildContext context,
    PostJobController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informative Auto-Assign Header Banner with Quick "Select All" Button
        Obx(() {
          final isGlobalActive = controller.chauffeurSelectionType.value == 'global';
          final count = controller.selectedServiceAreas.length;

          return Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isGlobalActive
                  ? AppColors.primaryColor.withValues(alpha: 0.12)
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isGlobalActive
                    ? AppColors.primaryColor.withValues(alpha: 0.6)
                    : const Color(0xFF2C2C2C),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: isGlobalActive
                        ? AppColors.primaryColor
                        : const Color(0xFF27272A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore_outlined,
                    color: isGlobalActive ? Colors.black : AppColors.primaryColor,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Assign Chauffeur',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        count == 0
                            ? 'Select service area below to auto-assign'
                            : 'Auto-assigning in ${controller.selectedServiceAreas.join(', ')}',
                        style: GoogleFonts.inter(
                          color: isGlobalActive && count > 0
                              ? AppColors.primaryColor
                              : Colors.grey.shade400,
                          fontSize: 12.sp,
                          fontWeight: count > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (count > 0)
                  GestureDetector(
                    onTap: () => controller.clearServiceAreaSelection(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28282E),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "Clear",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),

        SizedBox(height: 16.h),

        // Service Area Selection List (Multi-Select Area Cards)
        Obx(() {
          if (controller.isServiceAreasLoading.value &&
              controller.serviceAreas.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              ),
            );
          }

          if (controller.serviceAreas.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'No service areas found.',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 13.sp,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Service Area',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ...controller.serviceAreas.map((areaItem) {
                final areaName = areaItem.areaName;
                final isActive = areaItem.status == 'ACTIVE';
                final isSelected = controller.selectedServiceAreas.contains(areaName);

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.1)
                        : const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : const Color(0xFF27272A),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (!isActive) {
                        Helpers.showCustomSnackBar(
                          "The $areaName service area is currently inactive.",
                          isError: true,
                        );
                      } else {
                        controller.toggleServiceAreaSelection(areaName);
                      }
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Container(
                            width: 22.w,
                            height: 22.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : Colors.grey.shade600,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 14.sp,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              areaName,
                              style: GoogleFonts.inter(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade200,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isActive)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                "INACTIVE",
                                style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  static Widget _buildFavoriteChauffeurTab(
    BuildContext context,
    PostJobController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favorite Chauffeurs',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            Obx(
              () => controller.isFavoriteDriversLoading.value
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    )
                  : InkWell(
                      onTap: () => controller.fetchFavoriteDrivers(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Refresh',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // Chauffeur list items from API
        Obx(() {
          if (controller.isFavoriteDriversLoading.value &&
              controller.favoriteDrivers.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              ),
            );
          }

          if (controller.favoriteDrivers.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'No favorite chauffeurs found.',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 13.sp,
                ),
              ),
            );
          }

          return Column(
            children: controller.favoriteDrivers.map((driver) {
              final isSelected =
                  controller.chauffeurSelectionType.value == 'favorites' &&
                      controller.selectedDrivers.contains(driver.id);

              final subtitleText = driver.company.isNotEmpty
                  ? driver.company
                  : (driver.serviceArea.isNotEmpty
                      ? driver.serviceArea
                      : 'Chauffeur');

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: GestureDetector(
                  onTap: () => controller.toggleDriverSelection(driver.id),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : const Color(0xFF2C2C2C),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.grey.shade600,
                          size: 22.sp,
                        ),
                        SizedBox(width: 14.w),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final preferredController =
                                Get.isRegistered<PreferredDriversController>()
                                    ? Get.find<PreferredDriversController>()
                                    : Get.put(PreferredDriversController());

                            preferredController.openChauffeurProfile(
                              userId: driver.id,
                              name: driver.name,
                              imageUrl: driver.profilePicture,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : const Color(0xFF2C2C2C),
                                width: 1,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 22.r,
                              backgroundImage: driver.profilePicture.isNotEmpty
                                  ? NetworkImage(driver.profilePicture)
                                  : null,
                              backgroundColor: const Color(0xFF27272A),
                              child: driver.profilePicture.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white54,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      driver.name,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (driver.badges.isNotEmpty) ...[
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      child: Text(
                                        driver.badges.first.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          color: Colors.black,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$subtitleText • ',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey.shade500,
                                        fontSize: 13.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.star,
                                    color: AppColors.primaryColor,
                                    size: 13.sp,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    driver.averageRating > 0
                                        ? driver.averageRating.toString()
                                        : '0.0',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade500,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final preferredController =
                                Get.isRegistered<PreferredDriversController>()
                                    ? Get.find<PreferredDriversController>()
                                    : Get.put(PreferredDriversController());

                            preferredController.openChauffeurProfile(
                              userId: driver.id,
                              name: driver.name,
                              imageUrl: driver.profilePicture,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF3F3F46),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13.sp,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildTabBar(PostJobController controller) {
    return Obx(
      () => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.changeJobType('One Way'),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  decoration: BoxDecoration(
                    color: controller.jobType.value == 'One Way'
                        ? AppColors.primaryColor
                        : const Color(0xFF1F1C1C),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF364153)),
                  ),
                  child: Center(
                    child: Text(
                      'One Way',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: controller.jobType.value == 'One Way'
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.changeJobType('By the hour'),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  decoration: BoxDecoration(
                    color: controller.jobType.value == 'By the hour'
                        ? AppColors.primaryColor
                        : const Color(0xFF1F1C1C),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF364153)),
                  ),
                  child: Center(
                    child: Text(
                      'By the hour',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: controller.jobType.value == 'By the hour'
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
