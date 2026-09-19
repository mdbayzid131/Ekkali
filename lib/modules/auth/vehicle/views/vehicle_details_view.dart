import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/services/user_profile_service.dart';
import 'package:moeb_26/core/widgets/ImagePreviewPopup.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/data/models/user_profile_model.dart';
import 'package:moeb_26/modules/auth/profile/controllers/profile_controller.dart';

class VehicleDetailsView extends StatefulWidget {
  const VehicleDetailsView({super.key});

  @override
  State<VehicleDetailsView> createState() => _VehicleDetailsViewState();
}

class _VehicleDetailsViewState extends State<VehicleDetailsView> {
  final UserProfileService _profileService = Get.find<UserProfileService>();
  final ProfileController _profileController = Get.find<ProfileController>();

  late String vehicleId;
  Vehicle? cachedVehicle;
  late Future<Vehicle?> _vehicleFuture;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      vehicleId = args['vehicleId'] ?? (args['vehicle'] as Vehicle?)?.id ?? '';
      cachedVehicle = args['vehicle'] as Vehicle?;
    } else if (args is String) {
      vehicleId = args;
    } else {
      vehicleId = '';
    }

    _vehicleFuture = _fetchVehicleDetails();
  }

  Future<Vehicle?> _fetchVehicleDetails() async {
    if (vehicleId.isEmpty) return cachedVehicle;
    try {
      final response = await _profileService.getVehicleById(vehicleId);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data is Map<String, dynamic>) {
          return Vehicle.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint("Error loading vehicle details: $e");
    }
    return cachedVehicle;
  }

  void _refresh() {
    setState(() {
      _vehicleFuture = _fetchVehicleDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomSubAppBar(
        title: "Vehicle Details",
      ),
      body: FutureBuilder<Vehicle?>(
        future: _vehicleFuture,
        initialData: cachedVehicle,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            );
          }

          final vehicle = snapshot.data;
          if (vehicle == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: const Color(0xFF888888),
                    size: 48.sp,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Vehicle not found",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF222222),
                    ),
                    child: const Text("Go Back"),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryColor,
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status / Review Notice Banner
                  _buildStatusNotice(vehicle),
                  SizedBox(height: 14.h),

                  // Hero Vehicle Header Card
                  _buildHeroHeader(vehicle),
                  SizedBox(height: 16.h),

                  // Vehicle Photo Gallery
                  _buildPhotoGallery(vehicle),
                  SizedBox(height: 16.h),

                  // Specifications Card
                  _buildSpecsCard(vehicle),
                  SizedBox(height: 16.h),

                  // Compliance & Documents Card
                  _buildDocumentsCard(vehicle),
                  SizedBox(height: 30.h),

                  // Bottom Action Buttons
                  _buildActionButtons(vehicle),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Review Status Notice Banner
  Widget _buildStatusNotice(Vehicle vehicle) {
    final status = vehicle.status.toUpperCase().replaceAll('_', ' ').trim();

    if (status.contains("REJECT") || status.contains("DECLIN")) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1414),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF381F1F)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cancel_rounded,
                  color: const Color(0xFFD46B6B),
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  "Vehicle Rejected",
                  style: GoogleFonts.inter(
                    color: const Color(0xFFD46B6B),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (vehicle.rejectionReason != null &&
                vehicle.rejectionReason!.trim().isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                "Reason: ${vehicle.rejectionReason}",
                style: GoogleFonts.inter(
                  color: const Color(0xFFD48A8A),
                  fontSize: 12.sp,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (status.contains("APPROV") || status.contains("ACTIVE")) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFF131D17),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF223A2B)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: const Color(0xFF5EBA84),
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "This vehicle is approved and active for rides.",
                style: GoogleFonts.inter(
                  color: const Color(0xFF5EBA84),
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default: Pending Review
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A14),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF382F20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: const Color(0xFFC7A15E),
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              "Under Review: Admin approval required before activation.",
              style: GoogleFonts.inter(
                color: const Color(0xFFC7A15E),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hero Header Card with Title, Type, Status
  Widget _buildHeroHeader(Vehicle vehicle) {
    final displayName = vehicle.year > 0
        ? "${vehicle.year} ${vehicle.makeAndModel}"
        : vehicle.makeAndModel;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Vehicle Type Chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: const Color(0xFF2C2C2C)),
                ),
                child: Text(
                  vehicle.carType.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCCCCCC),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Status Badge
              _buildComfortableStatusBadge(vehicle.status),
            ],
          ),
          SizedBox(height: 12.h),

          // Title
          Text(
            displayName,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          SizedBox(height: 8.h),

          // License Plate Pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  color: const Color(0xFF9E9E9E),
                  size: 13.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  vehicle.licensePlate.isNotEmpty
                      ? vehicle.licensePlate
                      : "NO PLATE",
                  style: GoogleFonts.inter(
                    color: const Color(0xFFD4D4D4),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Photo Gallery Section
  Widget _buildPhotoGallery(Vehicle vehicle) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "VEHICLE PHOTOS",
            style: GoogleFonts.inter(
              color: const Color(0xFF707070),
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildPhotoTile(
                  "Front View",
                  vehicle.vehiclePhotoFront,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildPhotoTile(
                  "Rear View",
                  vehicle.vehiclePhotoRear,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildPhotoTile(
                  "Interior View",
                  vehicle.vehiclePhotoInterior,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(String title, String? imageUrl) {
    final hasPhoto = imageUrl != null && imageUrl.trim().isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: hasPhoto
              ? () {
                  Get.dialog(
                    ImagePreviewPopup(imageUrl: imageUrl, title: title),
                  );
                }
              : null,
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFF282828)),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Color(0xFF555555),
                            size: 22,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF555555),
                      size: 24,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          title,
          style: GoogleFonts.inter(
            color: const Color(0xFF888888),
            fontSize: 11.sp,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Specifications Card
  Widget _buildSpecsCard(Vehicle vehicle) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SPECIFICATIONS",
            style: GoogleFonts.inter(
              color: const Color(0xFF707070),
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.h),
          _buildDetailRow("Make & Model", vehicle.makeAndModel),
          _buildDetailRow("Year", vehicle.year > 0 ? "${vehicle.year}" : "N/A"),
          _buildDetailRow("Vehicle Class", vehicle.carType),
          _buildDetailRow("License Plate", vehicle.licensePlate),
          _buildDetailRow(
            "Exterior Color",
            vehicle.colorOutside.isNotEmpty ? vehicle.colorOutside : "N/A",
          ),
          _buildDetailRow(
            "Interior Color",
            vehicle.colorInside.isNotEmpty ? vehicle.colorInside : "N/A",
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// Compliance & Documents Card
  Widget _buildDocumentsCard(Vehicle vehicle) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "COMPLIANCE & DOCUMENTS",
            style: GoogleFonts.inter(
              color: const Color(0xFF707070),
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.h),

          // Vehicle Registration Tile
          _buildDocumentTile(
            title: "Vehicle Registration",
            expiryDate: vehicle.vehicleRegistrationExpiryDate,
            imageUrl: vehicle.vehicleRegistrationImage,
          ),
          SizedBox(height: 10.h),

          // Commercial Insurance Tile
          _buildDocumentTile(
            title: "Commercial Insurance",
            expiryDate: vehicle.commercialInsuranceExpiryDate,
            imageUrl: vehicle.commercialInsuranceImage,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile({
    required String title,
    required String? expiryDate,
    required String? imageUrl,
  }) {
    String formattedDate = "N/A";
    if (expiryDate != null && expiryDate.isNotEmpty) {
      try {
        formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(expiryDate));
      } catch (_) {
        formattedDate = expiryDate;
      }
    }

    final hasFile = imageUrl != null && imageUrl.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: const Color(0xFF9E9E9E),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Expires: $formattedDate",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF808080),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (hasFile)
            InkWell(
              onTap: () {
                Get.dialog(
                  ImagePreviewPopup(imageUrl: imageUrl, title: title),
                );
              },
              borderRadius: BorderRadius.circular(6.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      color: const Color(0xFFB5B5B5),
                      size: 13.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "View",
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
            Text(
              "No File",
              style: GoogleFonts.inter(
                color: const Color(0xFF666666),
                fontSize: 11.sp,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF888888),
              fontSize: 13.sp,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFFD4D4D4),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Action Buttons (Set Active, Edit & Delete)
  Widget _buildActionButtons(Vehicle vehicle) {
    return Obx(() {
      final isSelected =
          _profileController.userProfile.value?.selectedVehicle == vehicle.id;
      final isUpdating = _profileController.isUpdating.value;

      return Column(
        children: [
          // Set as Active Button (if not already active)
          if (!isSelected) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () {
                        _profileController.updateSelectedVehicle(vehicle.id);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF132219),
                  side: const BorderSide(color: Color(0xFF244A32)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: const Color(0xFF5EBA84),
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Set as Active Vehicle for Rides",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF5EBA84),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFF112418),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFF224A30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF5EBA84),
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Currently Active Vehicle for Rides",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF5EBA84),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Edit & Delete Buttons Row
          Row(
            children: [
              // Edit Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed(
                      Routes.addNewVehicleView,
                      arguments: {"isEdit": true, "vehicle": vehicle},
                    )?.then((_) => _refresh());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    side: const BorderSide(color: Color(0xFF333333)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: const Color(0xFFDCDCDC),
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "Edit Vehicle",
                        style: GoogleFonts.inter(
                          color: const Color(0xFFDCDCDC),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Delete Button
              InkWell(
                onTap: () => _showDeleteConfirmation(vehicle.id),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  padding: EdgeInsets.all(14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1414),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFF382020)),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: const Color(0xFFD46B6B),
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildComfortableStatusBadge(String status) {
    final s = status.toUpperCase().replaceAll('_', ' ').trim();

    if (s.contains("APPROV") || s.contains("ACTIVE")) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFF131D17),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color(0xFF223A2B)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: const Color(0xFF5EBA84),
              size: 12.sp,
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
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1414),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color(0xFF381F1F)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cancel_rounded,
              color: const Color(0xFFD46B6B),
              size: 12.sp,
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

    // Default: Pending Review
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A14),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFF382F20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: const Color(0xFFC7A15E),
            size: 12.sp,
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
                        Get.back(); // close dialog
                        _profileController.deleteVehicle(vehicleId);
                        Get.back(); // return to fleet list
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
