import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/ImagePreviewPopup.dart';
import '../controllers/preferred_drivers_controller.dart';

class PreferredDriverProfileView extends StatefulWidget {
  const PreferredDriverProfileView({super.key});

  @override
  State<PreferredDriverProfileView> createState() =>
      _PreferredDriverProfileViewState();
}

class _PreferredDriverProfileViewState
    extends State<PreferredDriverProfileView> {
  int _selectedTabIndex = 0;

  String _formatReviewDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final PreferredDriversController controller =
        Get.find<PreferredDriversController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
          'Chauffeur Profile',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.5.h),
          child: Divider(
            color: const Color(0xFF1E1E1E),
            height: 1.5.h,
            thickness: 1.5.h,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isProfileLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        final chauffeur = controller.selectedChauffeur.value;

        if (chauffeur == null) {
          return Center(
            child: Text(
              'No chauffeur selected.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryColor,
          backgroundColor: const Color(0xFF1E1E1E),
          onRefresh: () => controller.fetchUserDetails(chauffeur.id),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Compact Hero Profile Card
                _buildCompactHeroCard(chauffeur, controller),
                SizedBox(height: 16.h),

                // Sleek Action Buttons Row (Message + Favorite)
                _buildActionButtons(chauffeur, controller),
                SizedBox(height: 20.h),

                // Modern Segmented Tab Bar (Info | Payment | Reviews)
                _buildSegmentedTabBar(),
                SizedBox(height: 16.h),

                // Tab Content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentTabContent(chauffeur, controller),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ===================== HERO CARD =====================
  Widget _buildCompactHeroCard(
      FavoriteChauffeur chauffeur, PreferredDriversController controller) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with golden border & rating star
          Stack(
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 2.w,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40.w),
                  child: chauffeur.imageUrl.isNotEmpty
                      ? Image.network(
                          chauffeur.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.person,
                                color: Colors.white54, size: 40),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.person,
                              color: Colors.white54, size: 40),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.black, size: 10.sp),
                      SizedBox(width: 2.w),
                      Text(
                        chauffeur.rating > 0
                            ? chauffeur.rating.toString()
                            : '0.0',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 14.w),

          // Name, Role & Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chauffeur.name.isNotEmpty
                      ? chauffeur.name +
                          (chauffeur.nickName != null &&
                                  chauffeur.nickName!.isNotEmpty
                              ? ' (${chauffeur.nickName})'
                              : '')
                      : 'N/A',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFEDB9B),
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  chauffeur.companyRole.isNotEmpty
                      ? chauffeur.companyRole
                      : 'Chauffeur',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFD5C4AB),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (chauffeur.badges.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  ...() {
                    final sortedBadges = List<String>.from(chauffeur.badges)
                      ..sort((a, b) {
                        if (a.toLowerCase().contains('elite')) return -1;
                        if (b.toLowerCase().contains('elite')) return 1;
                        return 0;
                      });
                    return sortedBadges.map(
                      (b) {
                        final bool isPartner =
                            b.toLowerCase().contains('partner');
                        final IconData badgeIcon = isPartner
                            ? Icons.emoji_events_rounded
                            : Icons.star_rounded;

                        return Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: const Color(0xFF3F3F46), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon,
                                    color: AppColors.primaryColor,
                                    size: 11.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  b,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFD5C4AB),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== ACTION BUTTONS =====================
  Widget _buildActionButtons(
      FavoriteChauffeur chauffeur, PreferredDriversController controller) {
    return Row(
      children: [
        // "Send a message" button
        Expanded(
          flex: 5,
          child: CustomButton(
            text: 'Send Message',
            onPressed: () => controller.startConversation(chauffeur),
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.black,
              size: 16.sp,
            ),
            fontSize: 13.sp,
            padding: EdgeInsets.symmetric(vertical: 10.h),
          ),
        ),
        SizedBox(width: 10.w),

        // Dynamic Favorite Toggle Button
        Expanded(
          flex: 4,
          child: Builder(
            builder: (context) {
              final currentChauffeur =
                  controller.selectedChauffeur.value ?? chauffeur;
              final bool isFav =
                  controller.isInFavorites(currentChauffeur.id) ||
                      currentChauffeur.isFavorite;

              if (isFav) {
                return CustomButton(
                  text: 'Saved',
                  onPressed: () =>
                      controller.removeFromFavorites(currentChauffeur),
                  backgroundColor: Colors.transparent,
                  textColor: const Color(0xFFFEDB9B),
                  borderColor: const Color(0xFFFEDB9B),
                  icon: Icon(
                    Icons.favorite,
                    color: const Color(0xFFFEDB9B),
                    size: 16.sp,
                  ),
                  fontSize: 12.sp,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                );
              } else {
                return CustomButton(
                  text: 'Favorite',
                  onPressed: () => controller.addToFavorites(currentChauffeur),
                  backgroundColor: Colors.transparent,
                  textColor: AppColors.primaryColor,
                  borderColor: AppColors.primaryColor,
                  icon: Icon(
                    Icons.favorite_border,
                    color: AppColors.primaryColor,
                    size: 16.sp,
                  ),
                  fontSize: 12.sp,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // ===================== SEGMENTED TABS =====================
  Widget _buildSegmentedTabBar() {
    final tabs = [
      {'label': 'Information', 'icon': Icons.person_outline},
      {'label': 'Payments', 'icon': Icons.payment_outlined},
      {'label': 'Reviews', 'icon': Icons.star_border_rounded},
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: 14.sp,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      tabs[index]['label'] as String,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontSize: 12.sp,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===================== CURRENT TAB CONTENT =====================
  Widget _buildCurrentTabContent(
      FavoriteChauffeur chauffeur, PreferredDriversController controller) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildInformationTab(chauffeur);
      case 1:
        return _buildPaymentsTab(chauffeur);
      case 2:
        return _buildReviewsTab(chauffeur, controller);
      default:
        return _buildInformationTab(chauffeur);
    }
  }

  // ===================== TAB 1: INFORMATION =====================
  Widget _buildInformationTab(FavoriteChauffeur chauffeur) {
    return Column(
      key: const ValueKey('tab_info'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chauffeur Personal & Company Information
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF161618),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF27272A), width: 1),
          ),
          child: Column(
            children: [
              _buildCompactInfoRow(
                icon: Icons.business_outlined,
                title: 'Company',
                value: chauffeur.companyName.trim().isNotEmpty
                    ? chauffeur.companyName
                    : 'N/A',
              ),
              _buildDivider(),
              _buildCompactInfoRow(
                icon: Icons.badge_outlined,
                title: 'Role',
                value: chauffeur.companyRole.trim().isNotEmpty
                    ? chauffeur.companyRole
                    : 'N/A',
              ),
              _buildDivider(),
              _buildCompactInfoRow(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: chauffeur.phone.trim().isNotEmpty
                    ? Helpers.formatPhoneNumber(chauffeur.phone)
                    : 'N/A',
                copyValue: Helpers.formatPhoneNumber(chauffeur.phone),
                isCopyable: true,
              ),
              _buildDivider(),
              _buildCompactInfoRow(
                icon: Icons.email_outlined,
                title: 'Email',
                value:
                    chauffeur.email.trim().isNotEmpty ? chauffeur.email : 'N/A',
                copyValue: chauffeur.email.trim(),
                isCopyable: true,
              ),
              _buildDivider(),
              _buildCompactInfoRow(
                icon: Icons.map_outlined,
                title: 'Service Area',
                value: chauffeur.serviceArea.trim().isNotEmpty
                    ? chauffeur.serviceArea
                    : 'N/A',
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),

        // Vehicles & Fleet Section
        _buildVehiclesSection(chauffeur),
      ],
    );
  }

  Widget _buildVehiclesSection(FavoriteChauffeur chauffeur) {
    final vehicles = chauffeur.vehicles.isNotEmpty
        ? chauffeur.vehicles
        : (chauffeur.vehicleName.isNotEmpty
            ? [
                ChauffeurVehicle(
                  type: 'Vehicle',
                  makeAndModel: chauffeur.vehicleName,
                )
              ]
            : <ChauffeurVehicle>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_car_filled_rounded,
                    color: AppColors.primaryColor,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Vehicles & Fleet',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD5C4AB),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (vehicles.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: const Color(0xFF3F3F46),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${vehicles.length} ${vehicles.length == 1 ? 'Vehicle' : 'Vehicles'}',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // Vehicle Cards
        if (vehicles.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFF161618),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFF27272A), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222226),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.directions_car_outlined,
                    color: const Color(0xFFD5C4AB),
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'No vehicles registered yet',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8E8E93),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < vehicles.length; i++)
                _buildVehicleItem(vehicles[i]),
            ],
          ),
      ],
    );
  }

  Widget _buildVehicleItem(ChauffeurVehicle vehicle) {
    final bool isSuv = vehicle.type.toLowerCase().contains('suv');
    final IconData vehicleIcon = isSuv
        ? Icons.directions_car_rounded
        : Icons.local_taxi_rounded;

    final displayName = vehicle.year > 0
        ? "${vehicle.year} ${vehicle.makeAndModel}"
        : (vehicle.makeAndModel.isNotEmpty
            ? vehicle.makeAndModel
            : 'Fleet Vehicle');

    final photos = vehicle.photosList;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Make & Model + Vehicle Type Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF222226),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: const Color(0xFF2E2E33),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    vehicleIcon,
                    color: AppColors.primaryColor,
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (vehicle.type.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFF3F3F46),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    vehicle.type.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFEDB9B),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),

          // Specs Badges Row (Plate & Color)
          if (vehicle.licensePlate.isNotEmpty || vehicle.color.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                if (vehicle.licensePlate.isNotEmpty)
                  _buildVehicleSpecBadge(
                    icon: Icons.tag,
                    label: 'License Plate: ${vehicle.licensePlate}',
                  ),
                if (vehicle.color.isNotEmpty)
                  _buildVehicleSpecBadge(
                    icon: Icons.palette_outlined,
                    label: 'Color: ${vehicle.color}',
                  ),
              ],
            ),
          ],

          // Vehicle 3 Photos Gallery (Front, Rear, Interior)
          if (photos.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Text(
              "VEHICLE PHOTOS",
              style: GoogleFonts.inter(
                color: const Color(0xFF8E8E93),
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: photos.map((p) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: _buildVehiclePhotoTile(
                      vehicleTitle: displayName,
                      photoTitle: p['title'] ?? 'Photo',
                      imageUrl: p['url'] ?? '',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleSpecBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFF2C2C32), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: const Color(0xFFFEDB9B)),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFFD5C4AB),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclePhotoTile({
    required String vehicleTitle,
    required String photoTitle,
    required String imageUrl,
  }) {
    final hasPhoto = imageUrl.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: hasPhoto
              ? () {
                  Get.dialog(
                    ImagePreviewPopup(
                      imageUrl: imageUrl,
                      title: "$vehicleTitle - $photoTitle",
                    ),
                  );
                }
              : null,
          child: Container(
            height: 70.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF202024),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFF2C2C32), width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF666666),
                            size: 20,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      Icons.directions_car_outlined,
                      color: const Color(0xFF555555),
                      size: 22.sp,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          photoTitle,
          style: GoogleFonts.inter(
            color: const Color(0xFF9E9EA8),
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ===================== TAB 2: PAYMENTS =====================
  Widget _buildPaymentsTab(FavoriteChauffeur chauffeur) {
    final String zelleText = chauffeur.zelle.trim();
    final String venmoText = chauffeur.venmo.trim();
    final String cashAppText = chauffeur.cashApp.trim();

    final String venmoDisplay = venmoText.isNotEmpty
        ? (venmoText.startsWith('@') ? venmoText : '@$venmoText')
        : 'N/A';
    final String cashAppDisplay = cashAppText.isNotEmpty
        ? (cashAppText.startsWith('\$') ? cashAppText : '\$$cashAppText')
        : 'N/A';

    return Container(
      key: const ValueKey('tab_payments'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
      ),
      child: Column(
        children: [
          _buildCompactInfoRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Zelle',
            value: zelleText.isNotEmpty ? zelleText : 'N/A',
            copyValue: zelleText,
            isCopyable: true,
          ),
          _buildDivider(),
          _buildCompactInfoRow(
            icon: Icons.payment_outlined,
            title: 'Venmo',
            value: venmoDisplay,
            copyValue: venmoDisplay,
            isCopyable: true,
          ),
          _buildDivider(),
          _buildCompactInfoRow(
            icon: Icons.monetization_on_outlined,
            title: 'Cash App',
            value: cashAppDisplay,
            copyValue: cashAppDisplay,
            isCopyable: true,
          ),
          _buildDivider(),
          _buildCompactInfoRow(
            icon: Icons.credit_card_outlined,
            title: 'Card Payment',
            value: chauffeur.cardPaymentAccepted
                ? 'Accepted ✅'
                : 'Not Accepted ❌',
            isCopyable: false,
          ),
        ],
      ),
    );
  }

  // ===================== TAB 3: REVIEWS =====================
  Widget _buildReviewsTab(
      FavoriteChauffeur chauffeur, PreferredDriversController controller) {
    return Column(
      key: const ValueKey('tab_reviews'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews Header with View All Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ratings & Feedback',
              style: GoogleFonts.inter(
                color: const Color(0xFFD5C4AB),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Obx(() {
              if (controller.reviewsList.length > 2 ||
                  controller.hasMoreReviews.value) {
                return GestureDetector(
                  onTap: () => _showAllReviewsBottomSheet(
                    context,
                    controller,
                    chauffeur,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.inter(
                          color: AppColors.primaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primaryColor,
                        size: 16.sp,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        SizedBox(height: 12.h),

        // Reviews List or Empty State
        Obx(() {
          final reviews = controller.reviewsList;
          if (controller.isReviewsLoading.value && reviews.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              ),
            );
          }

          if (reviews.isEmpty) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFF27272A), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    color: const Color(0xFFD5C4AB),
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'No ratings or reviews yet',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD5C4AB),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final displayList = reviews.take(2).toList();
          return Column(
            children: displayList.map((review) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildReviewCard(review),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  void _showAllReviewsBottomSheet(
    BuildContext context,
    PreferredDriversController controller,
    FavoriteChauffeur chauffeur,
  ) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Reviews & Feedback',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFEDB9B),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF222226), height: 1),

            // Reviews List with Infinite Scroll
            Expanded(
              child: Obx(() {
                if (controller.isReviewsLoading.value &&
                    controller.reviewsList.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                if (controller.reviewsList.isEmpty) {
                  return Center(
                    child: Text(
                      'No written reviews yet.',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade400,
                        fontSize: 14.sp,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  controller: controller.reviewsScrollController,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  itemCount: controller.reviewsList.length +
                      (controller.isMoreReviewsLoading.value ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      SizedBox(height: 14.h),
                  itemBuilder: (context, index) {
                    if (index == controller.reviewsList.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Center(
                          child: SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      );
                    }

                    final review = controller.reviewsList[index];
                    return _buildReviewCard(review);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildReviewCard(ChauffeurReview review) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating.floor()
                        ? Icons.star
                        : (index < review.rating
                            ? Icons.star_half
                            : Icons.star_border),
                    color: AppColors.primaryColor,
                    size: 14.sp,
                  ),
                ),
              ),
              Text(
                _formatReviewDate(review.reviewedAt),
                style: GoogleFonts.inter(
                  color: const Color(0xFFD5C4AB),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            review.comment.isNotEmpty ? '"${review.comment}"' : 'N/A',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: const Divider(color: Color(0xFF27272A), thickness: 1),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF27272A), width: 0.98),
                ),
                child: CircleAvatar(
                  radius: 13.r,
                  backgroundImage:
                      (review.reviewer?.profilePicture.isNotEmpty == true)
                          ? NetworkImage(review.reviewer!.profilePicture)
                          : null,
                  backgroundColor: const Color(0xFF27272A),
                  child: (review.reviewer?.profilePicture.isEmpty ?? true)
                      ? const Icon(
                          Icons.person,
                          size: 13,
                          color: Colors.white54,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                (review.reviewer?.name.isNotEmpty == true)
                    ? review.reviewer!.name
                    : 'Client',
                style: GoogleFonts.inter(
                  color: Colors.white,
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

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: const Divider(
        color: Color(0xFF27272A),
        thickness: 0.8,
      ),
    );
  }

  Widget _buildCompactInfoRow({
    required IconData icon,
    required String title,
    required String value,
    String? copyValue,
    bool isCopyable = false,
  }) {
    final bool canCopy =
        isCopyable && value.trim().isNotEmpty && value.trim() != 'N/A';
    final String textToCopy = copyValue ?? value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canCopy
            ? () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: textToCopy));
                Helpers.showCustomSnackBar(
                  '$title copied to clipboard: $textToCopy',
                  isError: false,
                );
              }
            : null,
        borderRadius: BorderRadius.circular(10.r),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.12),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF222226),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: const Color(0xFFD5C4AB), size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD5C4AB),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (canCopy) ...[
                SizedBox(width: 8.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222226),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFF2E2E33),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        color: AppColors.primaryColor,
                        size: 13.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Copy',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFEDB9B),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
