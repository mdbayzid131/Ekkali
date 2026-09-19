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
