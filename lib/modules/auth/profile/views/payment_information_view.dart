import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/Custom_AppBar.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/modules/auth/profile/controllers/profile_controller.dart';

class PaymentInformationView extends StatelessWidget {
  const PaymentInformationView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: 'Payment Methods & Payouts',
        showBackButton: true,
        showActions: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure Accepted Payment Channels',
                style: GoogleFonts.inter(
                  color: const Color(0xFFD5C4AB),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),

              // Zelle
              _buildInputField(
                label: 'Zelle Email / Phone',
                controller: controller.zelleController,
                hint: 'e.g. pay@chauffeur.com',
                icon: Icons.account_balance_wallet_outlined,
              ),

              // Venmo
              _buildInputField(
                label: 'Venmo Handle',
                controller: controller.venmoController,
                hint: 'e.g. @ChauffeurPay',
                icon: Icons.payment_outlined,
              ),

              // Cash App
              _buildInputField(
                label: 'Cash App Tag',
                controller: controller.cashAppController,
                hint: 'e.g. \$ChauffeurApp',
                icon: Icons.monetization_on_outlined,
              ),

              // Card Payment Switch Card
              Text(
                'Card Payments',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Obx(
                () => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.credit_card_outlined,
                          color: const Color(0xFFD5C4AB),
                          size: 19.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Accept Card Payments",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              "Allow affiliate / clients to pay via credit card",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF71717A),
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 14.w),
                      GestureDetector(
                        onTap: () {
                          controller.cardPaymentAccepted.value =
                              !controller.cardPaymentAccepted.value;
                        },
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: controller.cardPaymentAccepted.value
                                  ? AppColors.primaryColor
                                  : const Color(0xFF71717A),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                            color: controller.cardPaymentAccepted.value
                                ? AppColors.primaryColor
                                : Colors.transparent,
                          ),
                          child: controller.cardPaymentAccepted.value
                              ? Icon(
                                  Icons.check,
                                  color: Colors.black,
                                  size: 16.sp,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(
              top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
            ),
          ),
          child: Obx(
            () => CustomButton(
              text: controller.isUpdating.value ? "Saving..." : "Save Payment details",
              onPressed: () => controller.savePaymentDetails(),
              icon: controller.isUpdating.value
                  ? null
                  : const Icon(Icons.check_circle_outline, color: Colors.black),
              loading: controller.isUpdating.value,
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    required IconData icon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: controller,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF71717A),
                fontSize: 13.sp,
              ),
              prefixIcon: Icon(icon, color: Colors.white70, size: 19.sp),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
