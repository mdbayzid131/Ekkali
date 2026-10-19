import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountSuspendedWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AccountSuspendedWidget({
    super.key,
    this.title = "Account Suspended",
    this.message =
        "You cannot request or post jobs. You still have full access to your schedule, invoices, and expenses.",
    this.icon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          decoration: BoxDecoration(
            color: const Color(0xFF16120C),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: const Color(0xFFD97706).withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFFD97706).withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glowing Warning Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD97706).withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                      ),
                    ),
                  ),
                  Container(
                    width: 50.r,
                    height: 50.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF261A0C),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: const Color(0xFFFBBF24),
                        size: 26.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Title
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),

              // Description
              Text(
                message,
                style: GoogleFonts.inter(
                  color: const Color(0xFFFDE68A),
                  fontSize: 13.sp,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18.h),

              //   // Allowed Features Notice Pill
              //   Container(
              //     padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              //     decoration: BoxDecoration(
              //       color: Colors.white.withValues(alpha: 0.05),
              //       borderRadius: BorderRadius.circular(10.r),
              //       border: Border.all(
              //         color: Colors.white.withValues(alpha: 0.1),
              //         width: 1,
              //       ),
              //     ),
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         Icon(
              //           Icons.check_circle_outline_rounded,
              //           color: const Color(0xFF10B981),
              //           size: 16.sp,
              //         ),
              //         SizedBox(width: 8.w),
              //         Flexible(
              //           child: Text(
              //             "Schedule • Invoices • Expenses Active",
              //             style: GoogleFonts.inter(
              //               color: Colors.white70,
              //               fontSize: 11.5.sp,
              //               fontWeight: FontWeight.w500,
              //             ),
              //             maxLines: 1,
              //             overflow: TextOverflow.ellipsis,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }
}
