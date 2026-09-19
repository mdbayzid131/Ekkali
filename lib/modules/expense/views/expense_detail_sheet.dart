import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';

class ExpenseDetailSheet extends StatelessWidget {
  final ExpenseModel expense;
  final ExpenseController controller = Get.find<ExpenseController>();

  ExpenseDetailSheet({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF1A1A1A);
    const borderColor = Color(0xFF1E1E1E);
    final dateLongStr = DateFormat('EEEE, dd MMMM yyyy').format(expense.date);

    return Container(
      padding: EdgeInsets.only(
        top: 20.h,
        left: 20.w,
        right: 20.w,
        bottom: MediaQuery.of(context).padding.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top drag indicator and Header
            Center(
              child: Container(
                width: 50.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Expense Details",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: Colors.white, size: 22.sp),
                ),
              ],
            ),
            Divider(color: borderColor.withValues(alpha: 0.3), thickness: 1),
            SizedBox(height: 20.h),

            // Category Badge & Icon
            Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDCA1).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFDCA1).withValues(alpha: 0.2)),
                    ),
                    child: Icon(
                      controller.getCategoryIcon(expense.category),
                      color: const Color(0xFFFFDCA1),
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    expense.category,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    "\$${expense.amount.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFEDB9B),
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),

            // Details Group
            _buildDetailRow("Date", dateLongStr, borderColor),
            if (expense.description.isNotEmpty) ...[
              SizedBox(height: 15.h),
              _buildDetailRow("Notes / Description", expense.description, borderColor, isMultiline: true),
            ],
            
              // Attachment Preview
              if (expense.receiptImageUrl != null && expense.receiptImageUrl!.isNotEmpty) ...[
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Receipt Attachment",
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD5C4AB),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    InkWell(
                      onTap: () => controller.downloadReceiptImage(expense.receiptImageUrl!),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.file_download_outlined,
                              color: AppColors.primaryColor,
                              size: 16.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "Download",
                              style: GoogleFonts.inter(
                                color: AppColors.primaryColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () => _previewReceipt(context, expense.receiptImageUrl!),
                  child: Container(
                    height: 200.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                      image: DecorationImage(
                        image: expense.receiptImageUrl!.startsWith('http')
                            ? NetworkImage(expense.receiptImageUrl!) as ImageProvider
                            : FileImage(File(expense.receiptImageUrl!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 20.sp),
                            SizedBox(width: 6.w),
                            Text(
                              "Tap to zoom",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20.h),
            ],
          ),
        ),
      );
    }

  Widget _buildDetailRow(String label, String value, Color borderColor, {bool isMultiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFFD5C4AB),
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              height: isMultiline ? 1.4 : 1.0,
            ),
          ),
        ),
      ],
    );
  }

  void _previewReceipt(BuildContext context, String imagePath) {
    showFullScreenReceipt(context, imagePath);
  }

  static void showFullScreenReceipt(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            title: Text(
              "Receipt Picture",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.file_download_outlined,
                  color: AppColors.primaryColor,
                  size: 22.sp,
                ),
                tooltip: "Download Receipt",
                onPressed: () {
                  final controller = Get.isRegistered<ExpenseController>()
                      ? Get.find<ExpenseController>()
                      : Get.put(ExpenseController());
                  controller.downloadReceiptImage(imagePath);
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: imagePath.startsWith('http')
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFDCA1),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: Colors.white54, size: 60.sp),
                          SizedBox(height: 10.h),
                          Text(
                            "Failed to load receipt image",
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    )
                  : Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: Colors.white54, size: 60.sp),
                          SizedBox(height: 10.h),
                          Text(
                            "Failed to load receipt image",
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
