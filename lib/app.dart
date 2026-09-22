import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/bindings/initial_binding.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(376, 856),
      minTextAdapt: true,
      splitScreenMode: true,
      child: GetMaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.black100,
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
          datePickerTheme: AppTheme.datePickerTheme,
          timePickerTheme: AppTheme.timePickerTheme,
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF18181B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF2A2A30), width: 1),
            ),
          ),
          appBarTheme: const AppBarTheme(
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  Brightness.light, // For Android (light icons)
              statusBarBrightness: Brightness.dark, // For iOS (light icons)
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        getPages: Routes.routes,
        initialRoute: Routes.splashView,
        initialBinding: InitialBinding(),
      ),
    );
  }
}
