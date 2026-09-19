import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/my_jobs_model.dart';
import 'package:moeb_26/data/repositories/job_repository.dart';
import '../../my_jobs/controllers/my_jobs_controller.dart';

class JobEditController extends GetxController {
  final JobRepo _jobRepo = Get.find<JobRepo>();

  JobData? job;
  var isLoading = false.obs;

  // ASAP toggle
  var isAsap = false.obs;
  var showAsapError = false.obs;

  // Date & Time
  var selectedDate = Rxn<DateTime>();
  var selectedTime = Rxn<TimeOfDay>();
  var formattedTime = "".obs;

  // Vehicle & Payment
  var selectedVehicle = 'SEDAN'.obs;
  var selectedRole = 'Credit Card on File'.obs;
  final roles = ['Credit Card on File', 'Collect Payment'].obs;
  final vehicles = ['SEDAN', 'SUV', 'SPRINTER', 'LIMO STRETCH', 'SEDAN/SUV'];

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is JobData) {
      job = Get.arguments as JobData;
      initFields();
    }
  }

  String _normalizePaymentType(String? type) {
    if (type == null) return 'Credit Card on File';
    final t = type.toUpperCase();
    if (t.contains('COLLECT') && !t.contains('CREDIT') && !t.contains('NO_COLLECT') && !t.contains('NO COLLECT')) {
      return 'Collect Payment';
    }
    return 'Credit Card on File';
  }

  String _normalizeVehicleType(String? type) {
    if (type == null || type.isEmpty) return 'SEDAN';
    final t = type.toUpperCase().trim();
    if (t == 'SEDAN') return 'SEDAN';
    if (t == 'SUV') return 'SUV';
    if (t == 'SPRINTER') return 'SPRINTER';
    if (t == 'LIMO STRETCH' || t == 'LIMOSTRETCH') return 'LIMO STRETCH';
    if (t == 'SEDAN/SUV' || t == 'SEDAN / SUV') return 'SEDAN/SUV';
    return t;
  }

  void initFields() {
    if (job == null) return;

    selectedVehicle.value = _normalizeVehicleType(job!.vehicleType);
    selectedRole.value = _normalizePaymentType(job!.paymentType);
    isAsap.value = job!.asap == true;

    if (job!.date != null && job!.date!.isNotEmpty) {
      try {
        selectedDate.value = DateTime.tryParse(job!.date!);
      } catch (_) {}
    }

    if (job!.time != null && job!.time!.isNotEmpty) {
      try {
        final parts = job!.time!.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1].split(' ')[0]);
          if (job!.time!.toLowerCase().contains('pm') && hour < 12) hour += 12;
          if (job!.time!.toLowerCase().contains('am') && hour == 12) hour = 0;
          selectedTime.value = TimeOfDay(hour: hour, minute: minute);

          final now = DateTime.now();
          final dateTime = DateTime(now.year, now.month, now.day, hour, minute);
          formattedTime.value = DateFormat('hh:mm a').format(dateTime);
        }
      } catch (_) {}
    }
  }

  void toggleAsap(bool? val) {
    isAsap.value = val ?? false;
    if (isAsap.value) {
      showAsapError.value = false;
    }
  }

  void selectVehicle(String vehicle) {
    selectedVehicle.value = vehicle;
  }

  void pickRole(String role) {
    selectedRole.value = role;
  }

  Future<void> chooseDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFEDB9B),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF404040), width: 1),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  Future<void> chooseTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFEDB9B),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
              tertiaryContainer: Color(0xFFFEDB9B),
              onTertiaryContainer: Colors.black,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF404040), width: 1),
              ),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      selectedTime.value = picked;
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      formattedTime.value = DateFormat('hh:mm a').format(dateTime);
    }
  }

  Future<void> updateJob({
    required String pickupLocation,
    required String dropoffLocation,
    required String flightNumber,
    required String paymentAmount,
    required String instruction,
  }) async {
    if (job == null || job!.id == null) {
      Helpers.showCustomSnackBar('Invalid job reference.', isError: true);
      return;
    }

    if (!isAsap.value) {
      if (selectedDate.value == null) {
        Helpers.showCustomSnackBar('Please select a date or select ASAP.', isError: true);
        return;
      }
      if (selectedTime.value == null) {
        Helpers.showCustomSnackBar('Please select a time or select ASAP.', isError: true);
        return;
      }
    }

    try {
      isLoading.value = true;

      final isAsapRide = isAsap.value;
      final String? formattedDate = !isAsapRide && selectedDate.value != null
          ? "${selectedDate.value!.year.toString().padLeft(4, '0')}-${selectedDate.value!.month.toString().padLeft(2, '0')}-${selectedDate.value!.day.toString().padLeft(2, '0')}"
          : null;
      final String? formattedTimeStr = !isAsapRide && selectedTime.value != null
          ? "${selectedTime.value!.hour.toString().padLeft(2, '0')}:${selectedTime.value!.minute.toString().padLeft(2, '0')}"
          : null;

      final String normalizedPayment =
          (selectedRole.value.toUpperCase().contains("COLLECT") &&
                  !selectedRole.value.toUpperCase().contains("CREDIT"))
              ? "COLLECT PAYMENT"
              : "CREDIT CARD ON FILE";

      final response = await _jobRepo.updateJob(
        jobId: job!.id!,
        pickupLocation: pickupLocation.trim(),
        dropoffLocation: dropoffLocation.trim(),
        flightNumber: flightNumber.trim().isNotEmpty ? flightNumber.trim() : null,
        date: formattedDate,
        time: formattedTimeStr,
        asap: isAsapRide,
        vehicleType: selectedVehicle.value,
        paymentAmount: double.tryParse(paymentAmount) ?? (job!.paymentAmount?.toDouble() ?? 0.0),
        paymentType: normalizedPayment,
        jobType: job!.jobType ?? 'ONE WAY',
        instruction: instruction.trim().isNotEmpty ? instruction.trim() : '',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Close the edit screen first
        Get.back();

        Helpers.showCustomSnackBar('Job updated successfully.', isError: false);

        // Refresh the jobs list in BookingController
        if (Get.isRegistered<BookingController>()) {
          Get.find<BookingController>().fetchJobs(isRefresh: true);
        }
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to update job.')
            : 'Failed to update job.';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to update job.';
      Helpers.showCustomSnackBar(message, isError: true);
    } catch (e) {
      debugPrint("Error updating job: $e");
      Helpers.showCustomSnackBar('Something went wrong.', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
