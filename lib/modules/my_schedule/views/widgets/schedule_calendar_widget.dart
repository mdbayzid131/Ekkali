import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/modules/my_schedule/controllers/my_schedule_controller.dart';

class ScheduleCalendarWidget extends StatefulWidget {
  const ScheduleCalendarWidget({super.key});

  @override
  State<ScheduleCalendarWidget> createState() => _ScheduleCalendarWidgetState();
}

class _ScheduleCalendarWidgetState extends State<ScheduleCalendarWidget> {
  bool _isMonthView = false;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<MyScheduleController>();
    _displayedMonth = DateTime(
      controller.selectedDate.value.year,
      controller.selectedDate.value.month,
      1,
    );
  }

  void _nextMonthOrWeek() {
    setState(() {
      if (_isMonthView) {
        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
      } else {
        final controller = Get.find<MyScheduleController>();
        final nextWeek = controller.selectedDate.value.add(const Duration(days: 7));
        controller.selectDate(nextWeek);
        _displayedMonth = DateTime(nextWeek.year, nextWeek.month, 1);
      }
    });
  }

  void _prevMonthOrWeek() {
    setState(() {
      if (_isMonthView) {
        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
      } else {
        final controller = Get.find<MyScheduleController>();
        final prevWeek = controller.selectedDate.value.subtract(const Duration(days: 7));
        controller.selectDate(prevWeek);
        _displayedMonth = DateTime(prevWeek.year, prevWeek.month, 1);
      }
    });
  }

  void _openFullDatePicker(BuildContext context, MyScheduleController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: AppTheme.datePickerBuilder,
    );
    if (picked != null) {
      controller.selectDate(picked);
      setState(() {
        _displayedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final MyScheduleController controller = Get.find<MyScheduleController>();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        border: Border(bottom: BorderSide(color: Color(0xFF24242A), width: 1)),
      ),
      child: Obx(() {
        final selected = controller.selectedDate.value;
        final isTodaySelected =
            selected.year == DateTime.now().year &&
            selected.month == DateTime.now().month &&
            selected.day == DateTime.now().day;

        // Keep _displayedMonth in sync if selected date changes
        if (!_isMonthView &&
            (_displayedMonth.year != selected.year ||
                _displayedMonth.month != selected.month)) {
          _displayedMonth = DateTime(selected.year, selected.month, 1);
        }

        return Column(
          children: [
            // Calendar Top Control Bar (Month/Year, Arrows, Mode Toggle)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
              child: Row(
                children: [
                  // Left Control Group: < Month Year >
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _prevMonthOrWeek,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E22),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: const Color(0xFF2B2B32)),
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: GestureDetector(
                            onTap: () => _openFullDatePicker(context, controller),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('MMM yyyy').format(_displayedMonth),
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.primaryColor,
                                    size: 18.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: _nextMonthOrWeek,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E22),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: const Color(0xFF2B2B32)),
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 6.w),

                  // Right Control Group: Today & View Mode Toggle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isTodaySelected)
                        GestureDetector(
                          onTap: () {
                            final today = DateTime.now();
                            controller.selectDate(today);
                            setState(() {
                              _displayedMonth = DateTime(today.year, today.month, 1);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            margin: EdgeInsets.only(right: 6.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.primaryColor, width: 1),
                            ),
                            child: Text(
                              "Today",
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),

                      GestureDetector(
                        onTap: () => setState(() => _isMonthView = !_isMonthView),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: _isMonthView
                                ? AppColors.primaryColor
                                : const Color(0xFF1E1E22),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: _isMonthView
                                  ? AppColors.primaryColor
                                  : const Color(0xFF2B2B32),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isMonthView
                                    ? Icons.view_week_outlined
                                    : Icons.grid_view_rounded,
                                size: 13.sp,
                                color: _isMonthView ? Colors.black : AppColors.primaryColor,
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                _isMonthView ? "Week" : "Month",
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _isMonthView ? Colors.black : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Weekdays Header Row (MON TUE WED THU FRI SAT SUN)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Row(
                children: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray100,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            SizedBox(height: 4.h),

            // Dates View (Week Row vs Full Month Grid)
            if (_isMonthView)
              _buildFullMonthGrid(context, controller, selected)
            else
              _buildWeekRowView(context, controller, selected),

            SizedBox(height: 8.h),
          ],
        );
      }),
    );
  }

  // Week Row View (7 days)
  Widget _buildWeekRowView(
    BuildContext context,
    MyScheduleController controller,
    DateTime selected,
  ) {
    // Find Monday of current selected week
    final int weekday = selected.weekday; // 1 = Mon, 7 = Sun
    final monday = selected.subtract(Duration(days: weekday - 1));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: List.generate(7, (index) {
          final date = monday.add(Duration(days: index));
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: _buildDateCell(date, selected, controller),
            ),
          );
        }),
      ),
    );
  }

  // Full Month Grid View
  Widget _buildFullMonthGrid(
    BuildContext context,
    MyScheduleController controller,
    DateTime selected,
  ) {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    // Calculate grid items: offset for previous month days + current month days
    final offset = firstWeekday - 1; // days to pad before 1st day
    final totalCells = ((offset + daysInMonth) / 7).ceil() * 7;

    final startDate = firstDayOfMonth.subtract(Duration(days: offset));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.95,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          final isCurrentMonth = date.month == _displayedMonth.month;

          return _buildDateCell(date, selected, controller, isCurrentMonth: isCurrentMonth);
        },
      ),
    );
  }

  // Date Cell Rendering Helper
  Widget _buildDateCell(
    DateTime date,
    DateTime selected,
    MyScheduleController controller, {
    bool isCurrentMonth = true,
  }) {
    final isSelected =
        date.year == selected.year &&
        date.month == selected.month &&
        date.day == selected.day;

    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    final hasJobs = controller.hasJobsOnDate(date);

    return GestureDetector(
      onTap: () => controller.selectDate(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : (isToday ? const Color(0xFF222228) : const Color(0xFF1A1A1E)),
          borderRadius: BorderRadius.circular(12.r),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primaryColor, width: 1.2)
              : Border.all(color: const Color(0xFF2B2B32), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('d').format(date),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.black
                    : (isCurrentMonth ? Colors.white : Colors.white24),
              ),
            ),
            SizedBox(height: 2.h),
            if (hasJobs)
              Container(
                width: 4.r,
                height: 4.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.black : AppColors.primaryColor,
                ),
              )
            else
              SizedBox(height: 4.r),
          ],
        ),
      ),
    );
  }
}
