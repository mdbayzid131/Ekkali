import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moeb_26/config/themes/app_theme.dart';

class CustomJobButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double width;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final IconData? icon; // Added icon parameter
  final String? iconPath; // Added iconPath parameter for SVG support
  final double? iconSize; // Added iconSize parameter

  const CustomJobButton({
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
    this.iconPath,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ?? AppColors.primaryColor, // Default to primaryColor
          foregroundColor: textColor ?? Colors.black, // Default to black text
          elevation: 0,
          padding:
              padding ??
              EdgeInsets.symmetric(
                vertical: 16.h,
                horizontal: 24.w,
              ), // Default padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Align content in the center
          children: [
            if (iconPath != null)
              SvgPicture.asset(
                iconPath!,
                width: iconSize ?? 24.w,
                height: iconSize ?? 24.w,
                colorFilter: ColorFilter.mode(
                  textColor ?? Colors.black,
                  BlendMode.srcIn,
                ),
              )
            else
              Icon(
                icon ?? Icons.add,
                color: textColor ?? Colors.black, // Icon color
                size: iconSize ?? 24.sp, // Set the icon size
              ),
            SizedBox(width: 8.w), // Space between icon and text
            Flexible(
              child: Text(
                text,
                style:
                    style ??
                    GoogleFonts.inter(
                      fontSize:
                          fontSize ?? 16.sp, // Default font size with scaling
                      fontWeight:
                          fontWeight ??
                          FontWeight.bold, // Default to bold weight
                      color:
                          textColor ??
                          Colors.black, // Default to white text color
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
