import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';

class CustomDropdown extends StatefulWidget {
  final String hintText;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final ScrollController? scrollController;
  final bool isLoading;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final bool hasNextPage;

  const CustomDropdown({
    super.key,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.scrollController,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.hasNextPage = false,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          widget.isLoading ? "Loading service areas..." : widget.hintText,
          style: GoogleFonts.inter(
            color: AppColors.gray100,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        value: (widget.value == null || widget.value!.isEmpty || widget.isLoading)
            ? null
            : widget.value,
        items: [
          ...widget.items.map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (widget.isLoadingMore)
            const DropdownMenuItem<String>(
              enabled: false,
              value: 'loading',
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          if (widget.hasNextPage && !widget.isLoadingMore)
            DropdownMenuItem<String>(
              enabled: false,
              value: 'loadMore',
              child: GestureDetector(
                onTap: () {
                  if (widget.onLoadMore != null) {
                    widget.onLoadMore!();
                  }
                },
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    "Load More...",
                    style: GoogleFonts.inter(
                      color: AppColors.primaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
        onChanged: widget.isLoading
            ? null
            : (val) {
                if (val != 'loading' && val != 'loadMore') {
                  widget.onChanged(val);
                }
              },
        buttonStyleData: ButtonStyleData(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.black200),
            color: Colors.transparent,
          ),
        ),
        iconStyleData: IconStyleData(
          icon: widget.isLoading
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                )
              : Icon(
                  _isMenuOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 24.sp,
                  color: AppColors.gray100,
                ),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: const Color(0xFF1A1A1E),
            border: Border.all(color: const Color(0xFF2C2C2C), width: 1.2),
          ),
          offset: const Offset(0, -4),
          maxHeight: 260.h,
          scrollbarTheme: ScrollbarThemeData(
            radius: Radius.circular(40.r),
            thickness: WidgetStateProperty.all(4),
            thumbVisibility: WidgetStateProperty.all(true),
          ),
        ),
        menuItemStyleData: MenuItemStyleData(
          height: 40.h,
          padding: EdgeInsets.only(left: 14.w, right: 14.w),
        ),
        dropdownSearchData: widget.scrollController != null
            ? DropdownSearchData(
                searchInnerWidgetHeight: 0,
                searchInnerWidget: const SizedBox.shrink(),
                searchController: TextEditingController(),
                searchMatchFn: (item, searchValue) => true,
              )
            : null,
        selectedItemBuilder: (context) {
          List<Widget> builders = widget.items.map((String item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList();

          if (widget.isLoadingMore) {
            builders.add(const SizedBox.shrink());
          }
          if (widget.hasNextPage && !widget.isLoadingMore) {
            builders.add(const SizedBox.shrink());
          }

          return builders;
        },
        onMenuStateChange: (isOpen) {
          setState(() {
            _isMenuOpen = isOpen;
          });
        },
      ),
    );
  }
}
