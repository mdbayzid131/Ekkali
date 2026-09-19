import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/modules/invoice/views/invoice_settings_view.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import '../../../config/routes/app_pages.dart';
import '../controllers/invoice_controller.dart';
import 'invoice_detail_view.dart';

class InvoiceHistoryView extends GetView<InvoiceController> {
  const InvoiceHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomSubAppBar(
        title: 'Invoice',
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 22.sp,
            ),
            onPressed: () => Get.to(() => const InvoiceSettingsView()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilters(),

          // List Content
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              backgroundColor: Colors.black,
              onRefresh: () => controller.fetchInvoicesFromApi(),
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.invoiceHistory.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                // Apply dynamic filter
                final filteredList = controller.invoiceHistory.where((record) {
                  if (controller.selectedFilter.value == 'All') return true;
                  return record.status.toLowerCase() ==
                      controller.selectedFilter.value.toLowerCase();
                }).toList();

                if (filteredList.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 150.h),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: const Color(0xFF364153),
                              size: 64.sp,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No invoices found',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFD5C4AB),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Create an invoice to get started.',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF52525B),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  itemCount: filteredList.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    return _buildInvoiceCard(filteredList[index]);
                  },
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 96.h,
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
          ),
          child: CustomButton(
            text: 'Create Invoice',
            onPressed: () {
              controller.prepareNewInvoice();
              Get.toNamed(Routes.createInvoiceView);
            },
            padding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
        ),
        child: Row(
          children: ['All', 'Paid', 'Unpaid'].map((filter) {
            return Expanded(
              child: Obx(() {
                final isSelected = controller.selectedFilter.value == filter;
                return GestureDetector(
                  onTap: () => controller.selectedFilter.value = filter,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFDCA1) // Soft peach-yellow
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        12.r,
                      ), // More rounded corners
                    ),
                    child: Text(
                      filter,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? Colors.black
                            : const Color(0xFFD5C4AB),
                        fontSize: 13.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceHistoryRecord record) {
    final bool isPaid = record.status.toLowerCase() == 'paid';
    final Color badgeColor = isPaid
        ? const Color(0xFF10B981) // Green
        : const Color(0xFFEF4444); // Red

    // Format due date representation
    String dueDateDisplay = 'No due date';
    if (record.dueDate != 'No Due Date') {
      if (record.dueDate == 'On Receipt') {
        dueDateDisplay = 'Due: On Receipt';
      } else if (record.dueDate == 'Custom Due Date') {
        dueDateDisplay =
            'Due: ${DateFormat('MM/dd/yyyy').format(record.issuedDate)}';
      } else {
        final days = int.tryParse(record.dueDate.split(' ')[0]) ?? 0;
        final dueDate = record.issuedDate.add(Duration(days: days));
        dueDateDisplay =
            'Due date : ${DateFormat('MM/dd/yyyy').format(dueDate)}';
      }
    }

    // Avatar initials

    return GestureDetector(
      onTap: () {
        final trueIndex = controller.invoiceHistory.indexOf(record);
        if (trueIndex != -1) {
          if (record.id != null && record.id!.isNotEmpty) {
            controller.fetchInvoiceDetails(record.id!);
          }
          Get.to(() => InvoiceDetailView(index: trueIndex));
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(
            0xFF1A1A1A,
          ), // Dark premium card background matching rides_view
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Middle: Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.clientName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight:
                          FontWeight.w600, // Sleeker semi-bold font weight
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    record.invoiceNumber,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD5C4AB), // Warm beige
                      fontSize: 13.sp, // Slightly larger font size
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Icon(
                        dueDateDisplay.toLowerCase().contains('no due date')
                            ? Icons.event_busy_outlined
                            : Icons.calendar_today_outlined,
                        color: const Color(0xFFD5C4AB), // Warm beige
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          dueDateDisplay,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFD5C4AB), // Warm beige
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: Status & Amount Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r), // Pill shape
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: badgeColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Amount
                Text(
                  'USD ${record.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: isPaid ? const Color(0xFF10B981) : Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
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
