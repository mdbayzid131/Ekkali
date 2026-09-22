import 'package:flutter/material.dart';

class AppColors {
  //black colors
  static const black100 = Color(0xFF000000);
  static const black200 = Color(0xFF364153);
  //Gray colors
  static const gray100 = Color(0xFFA1A1A1);
  static const orange100 = Color(0xFFD08700);
  static const Color primaryColor = Color(0xFFFFDCA1);
  static const Color white100 = Color(0xFFFFFFFF);
}

class VehicleTypeColors {
  static const Color sedan = Color(0xFFDC2626);
  static const Color suv = Color(0xFF0A1F44);
  static const Color bus = Color(0xFF3E2723); // Dark Brown color
  static const Color sprinter = Color(0xFF000000);
  static const Color gray = Color.fromARGB(255, 65, 63, 63);

  static LinearGradient sedanSuvGradient = LinearGradient(
    colors: [
      const Color(0xFFB11226),
      const Color(0xFFB11226).withValues(alpha: 0.90),
      const Color(0xFF0A1F44).withValues(alpha: 0.95),
      const Color(0xFF0A1F44).withValues(alpha: 0.9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static dynamic getVehicleStyle(String? type) {
    if (type == null) return gray;
    final t = type.toUpperCase().trim();
    if (t == 'SUV') return suv;
    if (t == 'SEDAN') return sedan;
    if (t == 'BUS') return bus;
    if (t == 'SEDAN/SUV' || t == 'SEDAN / SUV') return sedanSuvGradient;
    if (t == 'SPRINTER') return sprinter;
    if (t == 'LIMO STRETCH' || t == 'LIMOSTRETCH' || t == 'LIMO') return bus;
    return gray;
  }
}

class AppTheme {
  static DatePickerThemeData get datePickerTheme => DatePickerThemeData(
        backgroundColor: const Color(0xFF18181B),
        headerBackgroundColor: const Color(0xFF18181B),
        headerForegroundColor: AppColors.primaryColor,
        surfaceTintColor: Colors.transparent,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          if (states.contains(WidgetState.disabled)) return Colors.white24;
          return Colors.white;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor;
          }
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          return AppColors.primaryColor;
        }),
        todayBorder: const BorderSide(
          color: AppColors.primaryColor,
          width: 1.5,
        ),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          return Colors.white;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor;
          }
          return null;
        }),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: Colors.white70,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static TimePickerThemeData get timePickerTheme => TimePickerThemeData(
        backgroundColor: const Color(0xFF18181B),
        hourMinuteColor: const Color(0xFF24242A),
        hourMinuteTextColor: Colors.white,
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor;
          }
          return const Color(0xFF24242A);
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return Colors.white70;
        }),
        dayPeriodBorderSide: const BorderSide(
          color: Color(0xFF33333C),
          width: 1,
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        dialHandColor: AppColors.primaryColor,
        dialBackgroundColor: const Color(0xFF24242A),
        dialTextColor: Colors.white,
        entryModeIconColor: AppColors.primaryColor,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: Colors.white70,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static Widget datePickerBuilder(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryColor,
          onPrimary: Colors.black,
          surface: Color(0xFF18181B),
          onSurface: Colors.white,
        ),
        datePickerTheme: datePickerTheme,
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2A2A30), width: 1),
          ),
        ),
      ),
      child: child!,
    );
  }

  static Widget timePickerBuilder(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryColor,
          onPrimary: Colors.black,
          surface: Color(0xFF18181B),
          onSurface: Colors.white,
          secondaryContainer: AppColors.primaryColor,
          onSecondaryContainer: Colors.black,
          tertiaryContainer: AppColors.primaryColor,
          onTertiaryContainer: Colors.black,
        ),
        timePickerTheme: timePickerTheme,
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2A2A30), width: 1),
          ),
        ),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
  }
}
