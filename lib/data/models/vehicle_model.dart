import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleModel {
  // Unique identifier to use as a stable Widget key
  final String id = DateTime.now().microsecondsSinceEpoch.toString();
  bool isDisposed = false;

  final RxString selectedVehicleType;
  final TextEditingController makeController;
  final TextEditingController modelController;
  final TextEditingController yearController;
  final TextEditingController colorInsideController;
  final TextEditingController colorOutsideController;
  final TextEditingController licensePlateController;

  // New Fields from DocumentsUpload
  final Rx<File?> commercialInsuranceFile = Rx<File?>(null);
  final TextEditingController commercialInsuranceExpireController;

  final Rx<File?> vehicleRegistrationFile = Rx<File?>(null);
  final TextEditingController vehicleRegistrationExpireController;

  final Rx<File?> frontViewFile = Rx<File?>(null);
  final Rx<File?> rearViewFile = Rx<File?>(null);
  final Rx<File?> interiorViewFile = Rx<File?>(null);

  VehicleModel({String? initialType})
    : selectedVehicleType = (initialType ?? '').obs,
      makeController = TextEditingController(),
      modelController = TextEditingController(),
      yearController = TextEditingController(),
      colorInsideController = TextEditingController(),
      colorOutsideController = TextEditingController(),
      licensePlateController = TextEditingController(),
      commercialInsuranceExpireController = TextEditingController(),
      vehicleRegistrationExpireController = TextEditingController();

  factory VehicleModel.fromVehicle(dynamic vehicle) {
    final model = VehicleModel(initialType: vehicle.carType);
    model.makeController.text = vehicle.make;
    model.modelController.text = vehicle.model;
    model.yearController.text = vehicle.year.toString();
    model.colorInsideController.text = vehicle.colorInside ?? '';
    model.colorOutsideController.text = vehicle.colorOutside ?? '';
    model.licensePlateController.text = vehicle.licensePlate;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      "carType": selectedVehicleType.value,
      "make": makeController.text,
      "model": modelController.text,
      "year": int.tryParse(yearController.text) ?? 0,
      "colorInside": colorInsideController.text,
      "colorOutside": colorOutsideController.text,
      "licensePlate": licensePlateController.text,
      "vehicleRegistrationExpiryDate": vehicleRegistrationExpireController.text,
      "commercialInsuranceExpiryDate": commercialInsuranceExpireController.text,
    };
  }

  void dispose() {
    if (isDisposed) return;
    isDisposed = true;
    makeController.dispose();
    modelController.dispose();
    yearController.dispose();
    colorInsideController.dispose();
    colorOutsideController.dispose();
    licensePlateController.dispose();
    commercialInsuranceExpireController.dispose();
    vehicleRegistrationExpireController.dispose();
  }
}
