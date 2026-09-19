import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';

class JobOfferCard extends StatelessWidget {
  final String time;
  final String pickupLocation;
  final String dropoffLocation;
  final String passengerName;
  final String companyName;
  final String vehicleType;
  final String price;
  final String? paymentType;
  final VoidCallback? onTap;

  const JobOfferCard({
    super.key,
    required this.time,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.passengerName,
    required this.companyName,
    required this.vehicleType,
    required this.price,
    this.paymentType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleStyle = VehicleTypeColors.getVehicleStyle(vehicleType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFF24242A), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Main Row: Time & Price on Left, Route Connector on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Time & Price
                SizedBox(
                  width: 75.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        "\$$price",
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFEDB9B),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // Right Column: Route Timeline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup Row
                      Row(
                        children: [
                          Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white70,
                                width: 2,
                              ),
                              color: Colors.transparent,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              pickupLocation,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Connecting Vertical Line
                      Padding(
                        padding: EdgeInsets.only(
                          left: 4.w,
                          top: 3.h,
                          bottom: 3.h,
                        ),
                        child: Container(
                          width: 2.w,
                          height: 16.h,
                          color: const Color(0xFF33333E),
                        ),
                      ),

                      // Dropoff Row
                      Row(
                        children: [
                          Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFEDB9B),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              dropoffLocation.isNotEmpty
                                  ? dropoffLocation
                                  : "As Directed",
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),
            Divider(color: const Color(0xFF22222A), height: 1.h, thickness: 1),
            SizedBox(height: 12.h),

            // Bottom Sub-Info Row: Company Name & Vehicle Category Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Company / Posted by Info
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        color: Colors.grey[400],
                        size: 16.sp,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          companyName.isNotEmpty ? companyName : passengerName,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // Vehicle Category Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: vehicleStyle is Color ? vehicleStyle : null,
                    gradient: vehicleStyle is Gradient ? vehicleStyle : null,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    vehicleType,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
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
