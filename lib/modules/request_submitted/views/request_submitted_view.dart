import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';

class RequestSubmittedView extends StatelessWidget {
  const RequestSubmittedView({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic rawJobData = Get.arguments;
    final data = _JobSubmittedData.from(rawJobData);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Application Status",
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 14.w),
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Container(
                width: 36.w,
                height: 36.w,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF262626)),
                ),
                child: SvgPicture.asset(
                  AppIcons.cross_icon,
                  colorFilter: const ColorFilter.mode(
                    Colors.white70,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),

              // Hero Status Circle with subtle ring
              _buildHeroBadge(),

              SizedBox(height: 20.h),

              // Status Pill Tag
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1810),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFFD08700).withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD08700),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Text(
                      "UNDER REVIEW",
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFEDB9B),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Title
              Text(
                "Application Submitted!",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              // Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Text(
                  "Your application has been sent to the job poster. Once they review and accept your offer, you will be notified immediately.",
                  style: GoogleFonts.inter(
                    color: const Color(0xFFA1A1AA),
                    fontSize: 13.sp,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 24.h),

              // Timeline Stepper Card
              _buildTimelineCard(),

              SizedBox(height: 18.h),

              // Job Details Card
              _buildJobDetailsCard(data),

              SizedBox(height: 28.h),

              // Bottom Action Buttons
              CustomButton(
                text: "Go to My Jobs",
                onPressed: () {
                  Get.offAllNamed(Routes.bottomNabbarView);
                },
              ),

              SizedBox(height: 10.h),

              CustomButton(
                text: "Browse More Jobs",
                backgroundColor: Colors.transparent,
                textColor: const Color(0xFFA1A1AA),
                borderColor: const Color(0xFF262626),
   
                onPressed: () => Get.back(),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds Hero Badge with clean gold palette
  Widget _buildHeroBadge() {
    return Container(
      width: 84.w,
      height: 84.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF161616),
        border: Border.all(
          color: const Color(0xFFD08700).withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      padding: EdgeInsets.all(12.r),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFD08700),
        ),
        child: Icon(Icons.task_alt_rounded, color: Colors.black, size: 38.sp),
      ),
    );
  }

  /// Builds Progress Timeline Stepper in clean monochrome/gold palette
  Widget _buildTimelineCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF222222), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Application Progress",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 14.h),
          _buildTimelineItem(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFFD08700),
            title: "Application Sent",
            subtitle: "Submitted just now",
            isDone: true,
            showLine: true,
          ),
          _buildTimelineItem(
            icon: Icons.hourglass_empty_rounded,
            iconColor: const Color(0xFFFEDB9B),
            title: "Poster Reviewing",
            subtitle: "Job poster is considering applicants",
            isDone: false,
            isActive: true,
            showLine: true,
          ),
          _buildTimelineItem(
            icon: Icons.directions_car_outlined,
            iconColor: const Color(0xFF52525B),
            title: "Approval & Ride Start",
            subtitle: "Ride details unlocked upon approval",
            isDone: false,
            showLine: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isDone = false,
    bool isActive = false,
    bool showLine = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isActive
                    ? const Color(0xFF1C1810)
                    : const Color(0xFF1E1E1E),
                border: Border.all(
                  color: isDone || isActive
                      ? const Color(0xFFD08700).withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 16.sp),
            ),
            if (showLine)
              Container(
                width: 2.w,
                height: 26.h,
                color: isDone
                    ? const Color(0xFFD08700).withValues(alpha: 0.6)
                    : const Color(0xFF262626),
              ),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isDone || isActive
                      ? Colors.white
                      : const Color(0xFF71717A),
                  fontSize: 13.sp,
                  fontWeight: isDone || isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: const Color(0xFF71717A),
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds Job Overview Details Card
  Widget _buildJobDetailsCard(_JobSubmittedData data) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF222222), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Job Offer",
                style: GoogleFonts.inter(
                  color: const Color(0xFFFEDB9B),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                data.amount,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: Color(0xFF222222), height: 1),
          SizedBox(height: 12.h),

          // Route Column
          Row(
            children: [
              Column(
                children: [
                  Icon(
                    Icons.circle,
                    color: const Color(0xFFD08700),
                    size: 10.sp,
                  ),
                  Container(
                    width: 2.w,
                    height: 22.h,
                    color: const Color(0xFF262626),
                  ),
                  Icon(
                    Icons.location_on,
                    color: const Color(0xFFD08700),
                    size: 12.sp,
                  ),
                ],
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.pickup,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      data.dropoff,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              _buildMiniChip(Icons.directions_car_outlined, data.vehicleType),
              _buildMiniChip(Icons.access_time_rounded, data.dateTime),
              _buildMiniChip(Icons.payments_outlined, data.paymentType),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD08700), size: 12.sp),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobSubmittedData {
  final String bookingNo;
  final String pickup;
  final String dropoff;
  final String dateTime;
  final String vehicleType;
  final String amount;
  final String paymentType;

  _JobSubmittedData({
    required this.bookingNo,
    required this.pickup,
    required this.dropoff,
    required this.dateTime,
    required this.vehicleType,
    required this.amount,
    required this.paymentType,
  });

  static String _formatDateTime(dynamic dateVal, dynamic timeVal) {
    String datePart = '';
    String timePart = '';

    if (dateVal != null) {
      final str = dateVal.toString().trim();
      final dt = DateTime.tryParse(str)?.toLocal();
      if (dt != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final jobDay = DateTime(dt.year, dt.month, dt.day);

        if (jobDay == today) {
          datePart = "Today, ${DateFormat('MMM dd').format(dt)}";
        } else if (jobDay == today.add(const Duration(days: 1))) {
          datePart = "Tomorrow, ${DateFormat('MMM dd').format(dt)}";
        } else if (jobDay == today.subtract(const Duration(days: 1))) {
          datePart = "Yesterday, ${DateFormat('MMM dd').format(dt)}";
        } else {
          datePart = DateFormat('EEE, MMM dd').format(dt);
        }
      } else if (str.isNotEmpty && str != 'null') {
        datePart = str;
      }
    }

    if (timeVal != null) {
      final str = timeVal.toString().trim();
      final timeDt = DateTime.tryParse(str)?.toLocal();
      if (timeDt != null && (str.contains('T') || str.contains('-'))) {
        timePart = DateFormat('hh:mm a').format(timeDt);
      } else if (str.isNotEmpty && str != 'null') {
        try {
          final parsed = DateFormat("HH:mm").parse(str);
          timePart = DateFormat("hh:mm a").format(parsed);
        } catch (_) {
          try {
            final parsed = DateFormat("HH:mm:ss").parse(str);
            timePart = DateFormat("hh:mm a").format(parsed);
          } catch (_) {
            timePart = str;
          }
        }
      }
    }

    if (datePart.isNotEmpty && timePart.isNotEmpty) {
      return "$datePart • $timePart";
    } else if (datePart.isNotEmpty) {
      return datePart;
    } else if (timePart.isNotEmpty) {
      return timePart;
    }
    return "ASAP";
  }

  factory _JobSubmittedData.from(dynamic job) {
    if (job == null) {
      return _JobSubmittedData(
        bookingNo: "",
        pickup: "N/A",
        dropoff: "N/A",
        dateTime: "ASAP",
        vehicleType: "Standard",
        amount: "\$0.00",
        paymentType: "Credit Card",
      );
    }
    if (job is Map) {
      final rawId = job['_id']?.toString() ?? job['id']?.toString() ?? '';
      final rawBookingNo = job['bookingNo']?.toString() ??
          (rawId.length >= 6
              ? 'OFFER-${rawId.substring(rawId.length - 6).toUpperCase()}'
              : (rawId.isNotEmpty ? 'OFFER-$rawId' : ''));

      final isAsap = job['asap'] == true;
      final rawAmount = job['paymentAmount'] ?? job['price'] ?? job['amount'];
      final formattedAmount = rawAmount != null
          ? (num.tryParse(rawAmount.toString()) != null
              ? "\$${num.parse(rawAmount.toString()).toStringAsFixed(2)}"
              : "\$$rawAmount")
          : "\$0.00";

      return _JobSubmittedData(
        bookingNo: rawBookingNo,
        pickup: job['pickup']?.toString() ??
            job['pickupLocation']?.toString() ??
            job['pickupAddress']?.toString() ??
            "Pickup Location",
        dropoff: job['dropoff']?.toString() ??
            job['dropoffLocation']?.toString() ??
            job['dropoffAddress']?.toString() ??
            "Dropoff Location",
        dateTime: isAsap
            ? "ASAP"
            : _formatDateTime(
                job['date'] ?? job['pickupDate'] ?? job['pickupDateTime'],
                job['time'] ?? job['pickupTime'],
              ),
        vehicleType: job['vehicleType']?.toString() ??
            job['carType']?.toString() ??
            job['type']?.toString() ??
            "Standard",
        amount: formattedAmount,
        paymentType: job['paymentType']?.toString() ??
            job['payment']?.toString() ??
            "Credit Card",
      );
    }
    try {
      final rawBookingNo = (job.bookingNo ?? job.id ?? "").toString();
      final bool isAsap = (job.asap == true);
      final rawAmount = job.paymentAmount ?? job.price ?? job.amount;
      final formattedAmount = rawAmount != null
          ? (num.tryParse(rawAmount.toString()) != null
              ? "\$${num.parse(rawAmount.toString()).toStringAsFixed(2)}"
              : "\$$rawAmount")
          : "\$0.00";

      return _JobSubmittedData(
        bookingNo: rawBookingNo,
        pickup: (job.pickupLocation ?? job.pickup ?? "Pickup Location").toString(),
        dropoff: (job.dropoffLocation ?? job.dropoff ?? "Dropoff Location").toString(),
        dateTime: isAsap
            ? "ASAP"
            : _formatDateTime(
                job.date ?? job.pickupDate ?? job.pickupDateTime,
                job.time ?? job.pickupTime,
              ),
        vehicleType: (job.vehicleType ?? job.carType ?? job.type ?? "Standard").toString(),
        amount: formattedAmount,
        paymentType: (job.paymentType ?? job.payment ?? "Credit Card").toString(),
      );
    } catch (_) {
      return _JobSubmittedData(
        bookingNo: "",
        pickup: "Pickup Location",
        dropoff: "Dropoff Location",
        dateTime: "ASAP",
        vehicleType: "Standard",
        amount: "\$0.00",
        paymentType: "Credit Card",
      );
    }
  }
}
