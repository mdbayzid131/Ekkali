import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/core/services/subscription_service.dart';
import 'package:moeb_26/core/widgets/premium_lock_widget.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/Custom_AppBar.dart';
import '../controllers/preferred_drivers_controller.dart';

class PreferredDriversView extends StatelessWidget {
  const PreferredDriversView({super.key});

  @override
  Widget build(BuildContext context) {
    final PreferredDriversController controller = Get.put(
      PreferredDriversController(),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: CustomAppBar(
          title: 'Favorite Chauffeurs',
          notificationCount: 3,
        ),
        body: Obx(() {
          final isPrem = Get.isRegistered<SubscriptionService>()
              ? Get.find<SubscriptionService>().isPremium.value
              : false;

          if (!isPrem) {
            return const PremiumLockWidget(
              icon: Icons.favorite_border_rounded,
              title: "Unlock Preferred Chauffeurs",
              description:
                  "Subscribe to Ekkali Premium to discover top-rated luxury chauffeurs, build your private driver network, and dispatch rides directly.",
            );
          }

          return Column(
            children: [
              SizedBox(height: 12.h),

              // ── Tab Bar ──────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  height: 46.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF2C2C2C)),
                  ),
                  child: TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicator: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'My Favorites'),
                      Tab(text: 'Find Chauffeurs'),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // ── Tab Content ──────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  children: [
                    // ── Tab 1: My Favorites ──────────────────────────
                    _MyFavoritesTab(controller: controller),

                    // ── Tab 2: Find Drivers ──────────────────────────
                    _FindDriversTab(controller: controller),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 1 — My Favorites
// ═══════════════════════════════════════════════════════
class _MyFavoritesTab extends StatelessWidget {
  final PreferredDriversController controller;
  const _MyFavoritesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 10.h),
          child: TextFormField(
            onChanged: (value) => controller.searchQuery.value = value,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
            decoration: _searchDecoration('Search favorites by name, phone...'),
          ),
        ),

        // Favorites list
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              );
            }

            final list = controller.filteredChauffeursList;
            if (list.isEmpty) {
              return RefreshIndicator(
                color: AppColors.primaryColor,
                backgroundColor: const Color(0xFF1E1E1E),
                onRefresh: () => controller.fetchFavorites(isRefresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 100.h),
                    _emptyState(
                      icon: Icons.favorite_border,
                      title: controller.searchQuery.isEmpty
                          ? 'No favorites yet'
                          : 'No matching chauffeur',
                      subtitle: controller.searchQuery.isEmpty
                          ? 'Go to "Find Chauffeurs" tab to discover and add chauffeurs.'
                          : 'Try a different name, phone or company.',
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primaryColor,
              backgroundColor: const Color(0xFF1E1E1E),
              onRefresh: () => controller.fetchFavorites(isRefresh: true),
              child: ListView.separated(
                controller: controller.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                itemCount:
                    list.length + (controller.isMoreLoading.value ? 1 : 0),
                separatorBuilder: (_, _) => SizedBox(height: 14.h),
                itemBuilder: (context, index) {
                  if (index == list.length) {
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
                  return _DriverCard(
                    chauffeur: list[index],
                    controller: controller,
                    isFavorite: true,
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// Tab 2 — Find Drivers
// ═══════════════════════════════════════════════════════
class _FindDriversTab extends StatelessWidget {
  final PreferredDriversController controller;
  const _FindDriversTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Global search bar
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 10.h),
          child: TextFormField(
            onChanged: (value) => controller.globalSearchQuery.value = value,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
            decoration: _searchDecoration('Search by name or phone number...'),
          ),
        ),

        // Results
        Expanded(
          child: Obx(() {
            if (controller.isGlobalLoading.value) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              );
            }

            final results = controller.filteredGlobalResults;
            if (results.isEmpty) {
              return RefreshIndicator(
                color: AppColors.primaryColor,
                backgroundColor: const Color(0xFF1E1E1E),
                onRefresh: () =>
                    controller.fetchGlobalChauffeurs(isRefresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 100.h),
                    _emptyState(
                      icon: Icons.search_off,
                      title: controller.globalSearchQuery.isEmpty
                          ? 'No chauffeurs available'
                          : 'No results found',
                      subtitle: controller.globalSearchQuery.isEmpty
                          ? 'No active platform chauffeurs found at this time.'
                          : 'Try searching with a different name or area.',
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primaryColor,
              backgroundColor: const Color(0xFF1E1E1E),
              onRefresh: () =>
                  controller.fetchGlobalChauffeurs(isRefresh: true),
              child: ListView.separated(
                controller: controller.globalScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                itemCount: results.length +
                    (controller.isGlobalMoreLoading.value ? 1 : 0),
                separatorBuilder: (_, _) => SizedBox(height: 14.h),
                itemBuilder: (context, index) {
                  if (index == results.length) {
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
                  final chauffeur = results[index];
                  return Obx(
                    () => _DriverCard(
                      chauffeur: chauffeur,
                      controller: controller,
                      isFavorite: controller.isInFavorites(chauffeur.id),
                      showAddToFavorites: true,
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// Driver Card Widget
// ═══════════════════════════════════════════════════════
class _DriverCard extends StatelessWidget {
  final FavoriteChauffeur chauffeur;
  final PreferredDriversController controller;
  final bool isFavorite;
  final bool showAddToFavorites;

  const _DriverCard({
    required this.chauffeur,
    required this.controller,
    required this.isFavorite,
    this.showAddToFavorites = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111113),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF222226), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor, width: 1.8.w),
            ),
            child: CircleAvatar(
              radius: 26.r,
              backgroundImage: chauffeur.imageUrl.isNotEmpty
                  ? NetworkImage(chauffeur.imageUrl)
                  : null,
              backgroundColor: const Color(0xFF27272A),
              child: chauffeur.imageUrl.isEmpty
                  ? Text(
                      chauffeur.name.isNotEmpty
                          ? chauffeur.name[0].toUpperCase()
                          : 'C',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(width: 14.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chauffeur.name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  chauffeur.serviceArea,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 11.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: AppColors.primaryColor,
                      size: 14.sp,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '${chauffeur.rating}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      chauffeur.ratingCount,
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          // Action column
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // View Profile button
              GestureDetector(
                onTap: () => controller.viewProfile(chauffeur),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFDCA1), Color(0xFFFEDB9B)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'View Profile',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Add / Remove from Favorites toggle (Find tab only)
              if (showAddToFavorites) ...[
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: () {
                    if (isFavorite) {
                      controller.removeFromFavorites(chauffeur);
                    } else {
                      controller.addToFavorites(chauffeur);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isFavorite
                          ? const Color(0xFF2A1C1C)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isFavorite
                            ? const Color(0xFFFEDB9B).withValues(alpha: 0.5)
                            : const Color(0xFF2C2C2C),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 12.sp,
                          color: isFavorite
                              ? const Color(0xFFFEDB9B)
                              : Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          isFavorite ? 'Saved' : 'Add',
                          style: GoogleFonts.inter(
                            color: isFavorite
                                ? const Color(0xFFFEDB9B)
                                : Colors.grey,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────
InputDecoration _searchDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14.sp),
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    prefixIcon: Padding(
      padding: EdgeInsets.only(left: 12.w, right: 8.w),
      child: Icon(Icons.search, color: Colors.grey, size: 22.sp),
    ),
    prefixIconConstraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
    contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: Color(0xFF242424), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: AppColors.primaryColor, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: Color(0xFF242424), width: 1),
    ),
  );
}

Widget _emptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 52.sp),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.grey.shade600,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    ),
  );
}
