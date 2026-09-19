import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/data/models/user_profile_model.dart';
import 'package:moeb_26/modules/auth/profile/controllers/profile_controller.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';

class AllVehicleView extends StatelessWidget {
  AllVehicleView({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    // Automatically trigger fresh fetch when opening this view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchVehicles();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomSubAppBar(title: "My Vehicles"),
      body: Obx(() {
        if (controller.isVehiclesLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        final vehicles = controller.vehiclesList;

        if (vehicles.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primaryColor,
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: () => controller.fetchVehicles(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                SizedBox(height: 180.h),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF262626),
                          ),
                        ),
                        child: Icon(
                          Icons.directions_car_outlined,
                          color: const Color(0xFF9E9E9E),
                          size: 44.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "No Vehicles in Your Fleet",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        "Add your professional vehicle to start receiving rides",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF888888),
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 160.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildAddNewVehicleButton(),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryColor,
                backgroundColor: const Color(0xFF1A1A1A),
                onRefresh: () => controller.fetchVehicles(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  itemCount: vehicles.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildInfoBanner();
                    }
                    final vehicle = vehicles[index - 1];
                    return Obx(() {
                      final isSelected =
                          controller.userProfile.value?.selectedVehicle ==
                              vehicle.id;
                      return _buildFleetVehicleCard(
                        context,
                        vehicle,
                        index - 1,
                        isSelected: isSelected,
                      );
                    });
                  },
                ),
              ),
            ),

            // Add New Vehicle Button at Bottom
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
              child: _buildAddNewVehicleButton(),
            ),
          ],
        );
      }),
    );
  }

  /// Informative banner
  Widget _buildInfoBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF262626),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.info_outline_rounded,
              color: const Color(0xFF9E9E9E),
              size: 16.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "Select your active vehicle for rides. Tap any vehicle for full details.",
              style: GoogleFonts.inter(
                color: const Color(0xFFA5A5A5),
                fontSize: 12.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Clean & lightweight fleet vehicle card (based on GET /api/v1/vehicles)
  Widget _buildFleetVehicleCard(
    BuildContext context,
    Vehicle vehicle,
    int index, {
    required bool isSelected,
  }) {
    final displayName = vehicle.year > 0
        ? "${vehicle.year} ${vehicle.makeAndModel}"
        : vehicle.makeAndModel;

    final isRejected = vehicle.status.toUpperCase().contains('REJECT') ||
        vehicle.status.toUpperCase().contains('DECLIN');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF285437)
              : (isRejected
                  ? const Color(0xFF4A2626)
                  : const Color(0xFF242424)),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () {
            Get.toNamed(
              Routes.vehicleDetailsView,
              arguments: {"vehicleId": vehicle.id, "vehicle": vehicle},
            )?.then((_) => controller.fetchVehicles());
          },
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Vehicle Type Tag & Status Badge + Active Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Vehicle Type Tag
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: const Color(0xFF2C2C2C),
                            ),
                          ),
                          child: Text(
                            vehicle.carType.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: const Color(0xFFCCCCCC),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),

                        // Active Vehicle Indicator
                        if (isSelected) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 3.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF112418),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: const Color(0xFF224A30),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: const Color(0xFF5EBA84),
                                  size: 11.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  "ACTIVE",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF5EBA84),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Status Badge
                    _buildComfortableStatusBadge(vehicle.status),
                  ],
                ),

                SizedBox(height: 12.h),

                // Middle Row: Icon + Make & Model + License Plate
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF132219)
                            : const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF244A32)
                              : const Color(0xFF262626),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.directions_car_rounded,
                          color: isSelected
                              ? const Color(0xFF5EBA84)
                              : const Color(0xFF8E8E8E),
                          size: 24,
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Vehicle Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isNotEmpty
                                ? displayName
                                : "Vehicle #${index + 1}",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),

                          // License Plate Pill
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 2.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(
                                color: const Color(0xFF2A2A2A),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.credit_card_outlined,
                                  color: const Color(0xFF9E9E9E),
                                  size: 12.sp,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  vehicle.licensePlate.isNotEmpty
                                      ? vehicle.licensePlate
                                      : "NO PLATE",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFC4C4C4),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Rejection Reason Box (if rejected)
                if (isRejected &&
                    vehicle.rejectionReason != null &&
                    vehicle.rejectionReason!.trim().isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1414),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFF3B2020),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: const Color(0xFFD47070),
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            "Reason: ${vehicle.rejectionReason}",
                            style: GoogleFonts.inter(
                              color: const Color(0xFFD48A8A),
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 10.h),
                Divider(
                  color: const Color(0xFF202020),
                  height: 1,
                ),
                SizedBox(height: 8.h),

                // Footer: Select Active Action + Edit & Delete Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Select as Active Button or View Details
                    if (!isSelected)
                      InkWell(
                        onTap: () {
                          controller.updateSelectedVehicle(vehicle.id);
                        },
                        borderRadius: BorderRadius.circular(6.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1B1B),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: const Color(0xFF2C2C2C),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.radio_button_unchecked,
                                color: const Color(0xFF9E9E9E),
                                size: 12.sp,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                "Set as Active",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFB5B5B5),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: const Color(0xFF5EBA84),
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "Active for Rides",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF5EBA84),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                    Row(
                      children: [
                        // Edit Button
                        InkWell(
                          onTap: () {
                            Get.toNamed(
                              Routes.addNewVehicleView,
                              arguments: {"isEdit": true, "vehicle": vehicle},
                            )?.then((_) => controller.fetchVehicles());
                          },
                          borderRadius: BorderRadius.circular(6.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1C),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: const Color(0xFF2C2C2C),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: const Color(0xFFC7C7C7),
                                  size: 12.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  "Edit",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFC7C7C7),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(width: 8.w),

                        // Delete Button
                        InkWell(
                          onTap: () => _showDeleteConfirmation(vehicle.id),
                          borderRadius: BorderRadius.circular(6.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1616),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: const Color(0xFF332020),
                              ),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: const Color(0xFFC46565),
                              size: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Subtle & soothing status badge
  Widget _buildComfortableStatusBadge(String status) {
    final s = status.toUpperCase().replaceAll('_', ' ').trim();

    if (s.contains("APPROV") || s.contains("ACTIVE")) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: const Color(0xFF131D17),
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: const Color(0xFF223A2B),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: const Color(0xFF5EBA84),
              size: 11.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              "Approved",
              style: GoogleFonts.inter(
                color: const Color(0xFF5EBA84),
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (s.contains("REJECT") || s.contains("DECLIN")) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1414),
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: const Color(0xFF381F1F),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cancel_rounded,
              color: const Color(0xFFD46B6B),
              size: 11.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              "Rejected",
              style: GoogleFonts.inter(
                color: const Color(0xFFD46B6B),
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Default / Pending Review
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A14),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(
          color: const Color(0xFF382F20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: const Color(0xFFC7A15E),
            size: 11.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            "Pending Review",
            style: GoogleFonts.inter(
              color: const Color(0xFFC7A15E),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewVehicleButton() {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          Routes.addNewVehicleView,
          arguments: {"isEdit": false},
        )?.then((_) => controller.fetchVehicles());
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: const Color(0xFF2C2C2C),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: const Color(0xFFD6D6D6),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              "Add New Vehicle",
              style: GoogleFonts.inter(
                color: const Color(0xFFD6D6D6),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String vehicleId) {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFF262626)),
        ),
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF201616),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF381F1F)),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: const Color(0xFFD46B6B),
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                "Delete Vehicle?",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "Are you sure you want to remove this vehicle? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF888888),
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF2E2E2E),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA0A0A0),
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.deleteVehicle(vehicleId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB33A3A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                      ),
                      child: Text(
                        "Delete",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
