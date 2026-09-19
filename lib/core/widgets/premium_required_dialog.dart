import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';

class PremiumRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onUpgradePressed;

  const PremiumRequiredDialog({
    super.key,
    this.title = 'Premium Feature',
    this.message =
        'This feature is exclusively available for Ekkali Premium members. Upgrade today to unlock full access!',
    this.buttonText = 'Explore Premium',
    this.onUpgradePressed,
  });

  /// Static helper to quickly show the premium dialog from anywhere in the app
  static void show({
    BuildContext? context,
    String title = 'Premium Feature',
    String message =
        'This feature is exclusively available for Ekkali Premium members. Upgrade today to unlock full access!',
    String buttonText = 'Explore Premium',
    VoidCallback? onUpgradePressed,
  }) {
    Get.dialog(
      PremiumRequiredDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onUpgradePressed: onUpgradePressed,
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: const Color(0xFF2A2A2A),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Crown Icon with glowing background
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.25),
                    AppColors.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primaryColor,
                  size: 32.sp,
                ),
              ),
            ),
            SizedBox(height: 18.h),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),

            // Message / Description
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF9E9E9E),
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),

            // Action Buttons
            Row(
              children: [
                // Cancel / Maybe Later button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF333333)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF888888),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Upgrade / Go to Subscription button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back(); // close dialog
                      if (onUpgradePressed != null) {
                        onUpgradePressed!();
                      } else {
                        Get.toNamed(Routes.subscriptionView);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
