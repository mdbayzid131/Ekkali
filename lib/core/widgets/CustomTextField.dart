import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moeb_26/config/themes/app_theme.dart';

import 'package:flutter/services.dart';

class Customtextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType textInputType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const Customtextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.prefixIcon,
    this.suffixIcon,
    required this.textInputType,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: textInputType,
      textCapitalization: textCapitalization,
      validator: validator,
      inputFormatters: inputFormatters,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.gray100),
        errorStyle: TextStyle(color: Colors.red, fontSize: 12.sp),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          vertical: 15.h,
          horizontal: 10.w,
        ), // Adjust padding
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
      ),
    );
  }
}

/// Automatically capitalizes the first letter of each word (e.g. "john smith" -> "John Smith")
class CapitalizeWordsInputFormatter extends TextInputFormatter {
  const CapitalizeWordsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final StringBuffer buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < newValue.text.length; i++) {
      final String char = newValue.text[i];
      if (char == ' ' || char == '-' || char == "'") {
        buffer.write(char);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
      }
    }

    final String formattedText = buffer.toString();
    return newValue.copyWith(
      text: formattedText,
      selection: newValue.selection,
    );
  }
}

/// Automatically formats input into standard US phone number format: (XXX) XXX-XXXX
class UsPhoneInputFormatter extends TextInputFormatter {
  const UsPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String newText = newValue.text;

    // If deleting and character was a formatting symbol, delete the preceding digit
    if (oldValue.text.length > newText.length) {
      final oldSelectionEnd = oldValue.selection.end;
      if (oldSelectionEnd > 0 && oldSelectionEnd <= oldValue.text.length) {
        final deletedChar = oldValue.text[oldSelectionEnd - 1];
        if (deletedChar == ')' ||
            deletedChar == ' ' ||
            deletedChar == '-' ||
            deletedChar == '(') {
          final textBeforeCursor =
              newValue.text.substring(0, newValue.selection.end);
          final lastDigitIndex = textBeforeCursor.lastIndexOf(RegExp(r'\d'));
          if (lastDigitIndex != -1) {
            newText = textBeforeCursor.substring(0, lastDigitIndex) +
                textBeforeCursor.substring(lastDigitIndex + 1) +
                newValue.text.substring(newValue.selection.end);
          }
        }
      }
    }

    // Extract digits only
    String digits = newText.replaceAll(RegExp(r'\D'), '');

    // Strip leading US country code 1 if 11 digits
    if (digits.length > 10 && digits.startsWith('1')) {
      digits = digits.substring(1);
    }
    // Limit to max 10 digits
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final StringBuffer buffer = StringBuffer();
    // Format as (XXX) XXX-XXXX
    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(digits[i]);
      if (i == 2) buffer.write(') ');
      if (i == 5) buffer.write('-');
    }

    final formatted = buffer.toString();

    // Determine cursor position based on digits before cursor
    int digitsBeforeCursor = 0;
    final int selEnd = newValue.selection.end.clamp(0, newText.length);
    for (int i = 0; i < selEnd; i++) {
      if (RegExp(r'\d').hasMatch(newText[i])) {
        digitsBeforeCursor++;
      }
    }
    if (digitsBeforeCursor > digits.length) {
      digitsBeforeCursor = digits.length;
    }

    int cursorOffset = 0;
    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor) {
        cursorOffset = i + 1;
        break;
      }
    }

    // Advance cursor past syntax characters
    if (cursorOffset < formatted.length) {
      if (formatted[cursorOffset] == ')') {
        cursorOffset = (cursorOffset + 2).clamp(0, formatted.length);
      } else if (formatted[cursorOffset] == ' ' ||
          formatted[cursorOffset] == '-') {
        cursorOffset = (cursorOffset + 1).clamp(0, formatted.length);
      }
    }

    if (digitsBeforeCursor == 0) {
      cursorOffset = formatted.isEmpty ? 0 : 1;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, formatted.length),
      ),
    );
  }
}

