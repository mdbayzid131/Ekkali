import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/core/services/job_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moeb_26/modules/jobs_posts/controllers/job_post_controller.dart';
import 'package:moeb_26/modules/jobs_posts/views/job_post_sheet_tabbar_view.dart';
import 'package:moeb_26/modules/my_schedule/models/my_schedule_job_model.dart';

class MyScheduleController extends GetxController {
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<MyScheduleJobModel> jobsList = <MyScheduleJobModel>[].obs;
  final RxList<String> eventDates = <String>[].obs;
  var isSubmitting = false.obs;

  var isLoading = false.obs;
  int? _lastFetchedMonth;
  int? _lastFetchedYear;

  @override
  void onInit() {
    super.onInit();
    fetchCalendarJobs();
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    if (_lastFetchedMonth != date.month || _lastFetchedYear != date.year) {
      fetchCalendarJobs(targetDate: date);
    }
  }

  Future<void> fetchCalendarJobs({DateTime? targetDate}) async {
    try {
      isLoading.value = true;
      final date = targetDate ?? selectedDate.value;
      _lastFetchedMonth = date.month;
      _lastFetchedYear = date.year;

      final response = await Get.find<JobService>().getCalendarJobs(
        month: date.month,
        year: date.year,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['data'] != null) {
          final resData = data['data'] as Map;
          if (resData.containsKey('eventDates')) {
            final datesList = resData['eventDates'] as List? ?? [];
            eventDates.assignAll(datesList.map((e) => e.toString()).toList());
          }

          final eventsJson = resData['events'] as List? ?? [];
          final loadedJobs = eventsJson
              .map((item) =>
                  MyScheduleJobModel.fromJson(item as Map<String, dynamic>))
              .toList();

          jobsList.assignAll(loadedJobs);
        }
      }
    } catch (e) {
      // Keep real state or empty list on network error
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> togglePaymentStatus(String id) async {
    final index = jobsList.indexWhere((j) => j.id == id);
    if (index == -1) return false;

    final current = jobsList[index];
    final newIsPaid = !current.isPaid;
    final newPaymentStatusStr = newIsPaid ? 'PAID' : 'UNPAID';

    try {
      isSubmitting.value = true;
      final response = await Get.find<JobService>().updateJob(
        jobId: current.id,
        paymentStatus: newPaymentStatusStr,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updated = current.copyWith(isPaid: newIsPaid);
        jobsList[index] = updated;
        jobsList.refresh();

        Helpers.showCustomSnackBar(
          'Payment status updated to $newPaymentStatusStr',
          isError: false,
        );
        return true;
      } else {
        final message =
            response.statusMessage ?? 'Failed to update payment status';
        Helpers.showCustomSnackBar(message, isError: true);
        return false;
      }
    } catch (e) {
      Helpers.showCustomSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  List<MyScheduleJobModel> get selectedDateJobs {
    final sel = selectedDate.value;
    return jobsList.where((job) {
      return job.pickupDateTime.year == sel.year &&
          job.pickupDateTime.month == sel.month &&
          job.pickupDateTime.day == sel.day;
    }).toList();
  }

  bool hasJobsOnDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    if (eventDates.contains(dateStr)) {
      return true;
    }
    return jobsList.any((job) =>
        job.pickupDateTime.year == date.year &&
        job.pickupDateTime.month == date.month &&
        job.pickupDateTime.day == date.day);
  }

  Future<bool> createDirectBooking(MyScheduleJobModel job) async {
    try {
      isSubmitting.value = true;

      final dateStr = DateFormat('yyyy-MM-dd').format(job.pickupDateTime);
      final timeStr = DateFormat('HH:mm').format(job.pickupDateTime);

      final fareText = job.fare.replaceAll(RegExp(r'[^\d.]'), '');
      final fareDouble = double.tryParse(fareText) ?? 0.0;

      final String pType = job.paymentMethod.toUpperCase().contains('COLLECT')
          ? 'COLLECT PAYMENT'
          : 'CREDIT CARD ON FILE';

      final response = await Get.find<JobService>().createJob(
        jobType: 'ONE WAY',
        pickup: job.pickupLocation,
        dropoff: job.dropoffLocation,
        date: dateStr,
        time: timeStr,
        vehicleType: job.vehicleType,
        paymentAmount: fareDouble,
        paymentType: pType,
        paymentStatus: job.isPaid ? 'PAID' : 'UNPAID',
        passengerName: job.clientName,
        passengerPhone: job.clientPhone,
        instruction: job.notes,
        flightNumber: job.flightNumber,
        dispatchType: 'PERSONAL NOTE',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        dynamic createdData;
        if (data is Map && data.containsKey('data')) {
          createdData = data['data'];
        } else {
          createdData = data;
        }

        final newJob = job.copyWith(
          id: (createdData != null && createdData['_id'] != null)
              ? createdData['_id']
              : job.id,
        );

        jobsList.add(newJob);
        jobsList.refresh();

        Helpers.showCustomSnackBar(
          'Direct booking added to your schedule',
          isError: false,
        );
        return true;
      } else {
        final message = response.statusMessage ?? 'Failed to create booking';
        Helpers.showCustomSnackBar(message, isError: true);
        return false;
      }
    } catch (e) {
      Helpers.showCustomSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateDirectBooking(MyScheduleJobModel updatedJob) async {
    try {
      isSubmitting.value = true;

      final dateStr =
          DateFormat('yyyy-MM-dd').format(updatedJob.pickupDateTime);
      final timeStr = DateFormat('HH:mm').format(updatedJob.pickupDateTime);

      final fareText = updatedJob.fare.replaceAll(RegExp(r'[^\d.]'), '');
      final fareDouble = double.tryParse(fareText) ?? 0.0;

      final String pType =
          updatedJob.paymentMethod.toUpperCase().contains('COLLECT')
              ? 'COLLECT PAYMENT'
              : 'CREDIT CARD ON FILE';

      final response = await Get.find<JobService>().updateJob(
        jobId: updatedJob.id,
        jobType: 'ONE WAY',
        pickupLocation: updatedJob.pickupLocation,
        dropoffLocation: updatedJob.dropoffLocation,
        date: dateStr,
        time: timeStr,
        vehicleType: updatedJob.vehicleType,
        paymentAmount: fareDouble,
        paymentType: pType,
        paymentStatus: updatedJob.isPaid ? 'PAID' : 'UNPAID',
        passengerName: updatedJob.clientName,
        passengerPhone: updatedJob.clientPhone,
        instruction: updatedJob.notes,
        flightNumber: updatedJob.flightNumber,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final index = jobsList.indexWhere((j) => j.id == updatedJob.id);
        if (index != -1) {
          jobsList[index] = updatedJob;
          jobsList.refresh();
        }
        Helpers.showCustomSnackBar(
          'Booking details updated successfully',
          isError: false,
        );
        return true;
      } else {
        final message = response.statusMessage ?? 'Failed to update booking';
        Helpers.showCustomSnackBar(message, isError: true);
        return false;
      }
    } catch (e) {
      Helpers.showCustomSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void addJob(MyScheduleJobModel job) {
    createDirectBooking(job);
  }

  void updateJob(MyScheduleJobModel updatedJob) {
    updateDirectBooking(updatedJob);
  }

  Future<void> deleteJob(String id) async {
    try {
      final response = await Get.find<JobService>().deleteJob(jobId: id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        jobsList.removeWhere((j) => j.id == id);
        Helpers.showCustomSnackBar(
          'Booking removed from your schedule',
          isError: false,
        );
      } else {
        jobsList.removeWhere((j) => j.id == id);
      }
    } catch (e) {
      jobsList.removeWhere((j) => j.id == id);
    }
  }

  void openChauffeurSelectionForDispatch(
      BuildContext context, MyScheduleJobModel job) {
    final postJobController = Get.isRegistered<PostJobController>()
        ? Get.find<PostJobController>()
        : Get.put(PostJobController());

    postJobController.fetchServiceAreas();
    postJobController.fetchFavoriteDrivers();

    JobPostSheetTabBarView.showChauffeurSelectionBottomSheet(
      context,
      postJobController,
      onDone: () {
        dispatchToNetwork(job, postJobController: postJobController);
      },
    );
  }

  Future<void> dispatchToNetwork(MyScheduleJobModel job,
      {PostJobController? postJobController}) async {
    try {
      isSubmitting.value = true;

      String dispatchType = "ALL CHAUFFEURS";
      String? serviceAreaId;
      List<String>? targetedChauffeurs;

      List<String> serviceAreaIds = [];
      if (postJobController != null) {
        final selectionType = postJobController.chauffeurSelectionType.value;
        if (selectionType == 'favorites' &&
            postJobController.selectedDrivers.isNotEmpty) {
          dispatchType = "TARGETED CHAUFFEURS";
          targetedChauffeurs = postJobController.selectedDrivers.toList();
        } else if (postJobController.selectedServiceAreas.isNotEmpty) {
          dispatchType = "ALL CHAUFFEURS";
          for (final areaName in postJobController.selectedServiceAreas) {
            final areaModel = postJobController.serviceAreas.firstWhereOrNull(
              (a) =>
                  a.areaName.trim().toLowerCase() ==
                  areaName.trim().toLowerCase(),
            );
            if (areaModel != null && areaModel.id.isNotEmpty) {
              serviceAreaIds.add(areaModel.id);
            }
          }
          if (serviceAreaIds.isNotEmpty) {
            serviceAreaId = serviceAreaIds.first;
          }
        }
      }

      final response = await Get.find<JobService>().updateJob(
        jobId: job.id,
        dispatchType: dispatchType,
        serviceAreaId: serviceAreaId,
        serviceAreaIds: serviceAreaIds.isNotEmpty ? serviceAreaIds : null,
        targetedChauffeurs: targetedChauffeurs,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final index = jobsList.indexWhere((j) => j.id == job.id);
        if (index != -1) {
          final updated = jobsList[index].copyWith(
            isDispatchedToNetwork: true,
            status: "Dispatched to Network",
          );
          jobsList[index] = updated;
          jobsList.refresh();
        }

        final selectionText = postJobController?.chauffeurSelectionText;
        final msg = selectionText != null && selectionText.isNotEmpty
            ? 'Job dispatched to network ($selectionText)!'
            : 'Job successfully dispatched to the network!';
        Helpers.showCustomSnackBar(msg, isError: false);
      } else {
        final message = response.statusMessage ?? 'Failed to dispatch job';
        Helpers.showCustomSnackBar(message, isError: true);
      }
    } catch (e) {
      Helpers.showCustomSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Helpers.showCustomSnackBar('Calling $phoneNumber...', isError: false);
      }
    } catch (_) {
      Helpers.showCustomSnackBar('Calling $phoneNumber...', isError: false);
    }
  }

  Future<void> sendTextMessage(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'sms', path: cleanPhone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Helpers.showCustomSnackBar('Messaging $phoneNumber...', isError: false);
      }
    } catch (_) {
      Helpers.showCustomSnackBar('Messaging $phoneNumber...', isError: false);
    }
  }
}
