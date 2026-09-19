import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'add_expense_view.dart';
import 'expense_detail_sheet.dart';

import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';

class ExpenseListView extends GetView<ExpenseController> {
  const ExpenseListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      const backgroundColor = AppColors.black100;
      const borderColor = Color(0xFF1E1E1E);
      const accentColor = AppColors.orange100;

      final totalAmount = controller.filteredTotalAmount;
      final periodLabel = controller.filterPeriod.value;

      // Group filtered expenses by category
      final Map<String, List<ExpenseModel>> groupedExpenses = {};
      for (var e in controller.filteredExpenses) {
        groupedExpenses.putIfAbsent(e.category, () => []).add(e);
      }

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: CustomSubAppBar(
          title: 'Expenses',
          actions: [
            // Monthly/Yearly Filter Option
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              tooltip: "Filter Period",
              offset: Offset(0, 48.h),
              color: const Color(0xFF1E1E20),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
              ),
              constraints: BoxConstraints(maxWidth: 165.w),
              onSelected: (val) {
                if (controller.filterPeriod.value != val) {
                  controller.filterPeriod.value = val;
                  controller.fetchExpenses();
                }
              },
              itemBuilder: (context) {
                final current = controller.filterPeriod.value;
                final activeColor = const Color(0xFFFFDCA1);
                return [
                  PopupMenuItem(
                    value: 'Monthly',
                    height: 38.h,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: current == 'Monthly'
                              ? activeColor
                              : Colors.white70,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Monthly View',
                          style: GoogleFonts.inter(
                            color: current == 'Monthly'
                                ? activeColor
                                : Colors.white70,
                            fontWeight: current == 'Monthly'
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Yearly',
                    height: 38.h,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: current == 'Yearly'
                              ? activeColor
                              : Colors.white70,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Yearly View',
                          style: GoogleFonts.inter(
                            color: current == 'Yearly'
                                ? activeColor
                                : Colors.white70,
                            fontWeight: current == 'Yearly'
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
            // Export PDF/CSV Options
            PopupMenuButton<String>(
              icon: const Icon(Icons.ios_share, color: Colors.white),
              tooltip: "Export Options",
              offset: Offset(0, 48.h),
              color: const Color(0xFF1E1E20),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
              ),
              constraints: BoxConstraints(maxWidth: 150.w),
              onSelected: (val) {
                if (val == 'csv') {
                  controller.exportToCSV();
                } else if (val == 'pdf') {
                  controller.exportToPDF();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'csv',
                  height: 38.h,
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        color: const Color(0xFF10B981),
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Export CSV',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  height: 38.h,
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        color: const Color(0xFFEF4444),
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Export PDF',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Month/Year period switcher
              _buildPeriodSwitcher(borderColor),

              // Summary Card
              _buildSummaryCard(
                totalAmount,
                periodLabel,
                borderColor,
                accentColor,
              ),

              // History list title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Categories Breakdown",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CustomTextgray(
                      text: "${controller.filteredExpenses.length} record(s)",
                      fontSize: 11.sp,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),

              // Excel-style Categories List (Expandable)
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  }
                  if (groupedExpenses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.gray100,
                            size: 44.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "No expenses for this period",
                            style: GoogleFonts.inter(
                              color: AppColors.gray100,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primaryColor,
                    backgroundColor: const Color(0xFF1E1E1E),
                    onRefresh: () => controller.fetchExpenses(isRefresh: true),
                    child: ListView.builder(
                      controller: controller.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount:
                          groupedExpenses.keys.length +
                          (controller.isLoadingMore.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == groupedExpenses.keys.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          );
                        }

                        final category = groupedExpenses.keys.elementAt(index);
                        final items = groupedExpenses[category]!;
                        return _buildCategoryExpansionTile(
                          context,
                          category,
                          items,
                          borderColor,
                          accentColor,
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        // Bottom Button to add new expense
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
          child: CustomButton(
            text: "Track New Expense",

            onPressed: () {
              Get.to(() => AddExpenseView());
            },
          ),
        ),
      );
    });
  }

  Widget _buildPeriodSwitcher(Color borderColor) {
    final dateStr = controller.filterPeriod.value == 'Monthly'
        ? DateFormat('MMMM yyyy').format(controller.filterDate.value)
        : DateFormat('yyyy').format(controller.filterDate.value);

    return Container(
      color: Colors.black26,
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.all(4.r),
            icon: Icon(Icons.chevron_left, color: Colors.white, size: 20.sp),
            onPressed: () => controller.previousPeriod(),
          ),
          Text(
            dateStr,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.all(4.r),
            icon: Icon(Icons.chevron_right, color: Colors.white, size: 20.sp),
            onPressed: () => controller.nextPeriod(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    double totalAmount,
    String periodLabel,
    Color borderColor,
    Color accentColor,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total $periodLabel Expenses",
                style: GoogleFonts.inter(
                  color: const Color(0xFFD5C4AB),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  periodLabel == 'Monthly' ? 'Monthly' : 'Yearly',
                  style: GoogleFonts.inter(
                    color: accentColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            "\$${totalAmount.toStringAsFixed(2)}",
            style: GoogleFonts.inter(
              color: const Color(0xFFFEDB9B),
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryExpansionTile(
    BuildContext context,
    String category,
    List<ExpenseModel> items,
    Color borderColor,
    Color accentColor,
  ) {
    final categoryTotal = items.fold(0.0, (sum, item) => sum + item.amount);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            unselectedWidgetColor: Colors.white54,
            visualDensity: const VisualDensity(vertical: -1.5),
            colorScheme: const ColorScheme.dark(primary: Colors.white),
          ),
          child: ExpansionTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -1.5),
            tilePadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
            leading: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDCA1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(
                controller.getCategoryIcon(category),
                color: const Color(0xFFFFDCA1),
                size: 16.sp,
              ),
            ),
            title: Text(
              category,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "${items.length} records",
              style: GoogleFonts.inter(
                color: AppColors.gray100,
                fontSize: 10.sp,
              ),
            ),
            trailing: Text(
              "\$${categoryTotal.toStringAsFixed(2)}",
              style: GoogleFonts.inter(
                color: const Color(0xFFFEDB9B),
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              // Excel-style subheader
              Container(
                color: Colors.black26,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Date",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        "Description",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Amount",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Actions",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Excel-style individual rows
              ...items.map((e) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white10, width: 0.5),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 8,
                        child: GestureDetector(
                          onTap: () => Get.bottomSheet(
                            ExpenseDetailSheet(expense: e),
                            isScrollControlled: true,
                            ignoreSafeArea: false,
                          ),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  DateFormat('dd MMM').format(e.date),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  e.description.isNotEmpty
                                      ? e.description
                                      : "No description",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "\$${e.amount.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.to(() => AddExpenseView(expenseToEdit: e));
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 4.r,
                                  top: 4.r,
                                  bottom: 4.r,
                                  right: 3.r,
                                ),
                                child: SvgPicture.asset(
                                  AppIcons.edit_icon,
                                  width: 13.sp,
                                  height: 13.sp,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white70,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.dialog(
                                  Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      padding: EdgeInsets.all(24.r),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A1A1E),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.black200.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(12.r),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: SvgPicture.asset(
                                              AppIcons.delete_icon,
                                              width: 24.sp,
                                              height: 24.sp,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Colors.redAccent,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          Text(
                                            "Delete Expense",
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            "Are you sure you want to delete this expense? This action cannot be undone.",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              color: AppColors.gray100,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          SizedBox(height: 24.h),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () => Get.back(),
                                                  style: TextButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 12.h,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12.r,
                                                          ),
                                                      side: BorderSide(
                                                        color: AppColors
                                                            .black200
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Cancel",
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white70,
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: CustomButton(
                                                  onPressed: () {
                                                    controller.deleteExpense(
                                                      e.id,
                                                    );
                                                    Get.back();
                                                  },
                                                  text: "Delete",
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  textColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 12.h,
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
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 3.r,
                                  top: 4.r,
                                  bottom: 4.r,
                                  right: 0,
                                ),
                                child: SvgPicture.asset(
                                  AppIcons.delete_icon,
                                  width: 13.sp,
                                  height: 13.sp,
                                  colorFilter: ColorFilter.mode(
                                    Colors.redAccent.withValues(alpha: 0.8),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
