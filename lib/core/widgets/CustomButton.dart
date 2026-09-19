import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Widget? icon;

  final bool loading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width = double.maxFinite,
    this.style,
    this.padding,
    this.borderColor,
    this.fontSize,
    this.fontWeight,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFFFFDCA1),
          foregroundColor: textColor ?? Colors.black,
          elevation: 0,
          padding:
              padding ??
              EdgeInsets.symmetric(vertical: 14.h), // Adjust padding if needed
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
          disabledBackgroundColor: (backgroundColor ?? const Color(0xFFFFDCA1))
              .withValues(alpha: 0.6),
        ),
        child: loading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor ?? Colors.black,
                ),
              )
            : (icon != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon!,
                        SizedBox(width: 8.w),
                        Text(
                          text,
                          style:
                              style ??
                              GoogleFonts.inter(
                                fontSize: fontSize ?? 15.sp,
                                fontWeight: fontWeight ?? FontWeight.w600,
                                color: textColor ?? Colors.black,
                              ),
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style:
                          style ??
                          GoogleFonts.inter(
                            fontSize: fontSize ?? 15.sp,
                            fontWeight: fontWeight ?? FontWeight.w600,
                            color: textColor ?? Colors.black,
                          ),
                    )),
      ),
    );
  }
}
