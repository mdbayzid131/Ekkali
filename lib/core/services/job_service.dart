import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/data/repositories/job_repository.dart';

class JobService extends GetxService {
  late JobRepo _jobRepo;

  @override
  void onInit() {
    super.onInit();
    _jobRepo = JobRepo(apiClient: Get.find());
  }

  Future<JobService> init() async {
    return this;
  }

  Future<Response> createJob({
    required String jobType,
    required String pickup,
    required String dropoff,
    required String vehicleType,
    required double paymentAmount,
    required String paymentType,
    required String dispatchType,
    bool asap = false,
    String? date,
    String? time,
    String? flightNumber,
    String? instruction,
    String? paymentStatus,
    String? passengerName,
    String? passengerPhone,
    List<String>? targetedChauffeurs,
    String? serviceAreaId,
    List<String>? serviceAreaIds,
  }) async {
    try {
      return await _jobRepo.createJob(
        jobType: jobType,
        pickup: pickup,
        dropoff: dropoff,
        vehicleType: vehicleType,
        paymentAmount: paymentAmount,
        paymentType: paymentType,
        dispatchType: dispatchType,
        asap: asap,
        date: date,
        time: time,
        flightNumber: flightNumber,
        instruction: instruction,
        paymentStatus: paymentStatus,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        targetedChauffeurs: targetedChauffeurs,
        serviceAreaId: serviceAreaId,
        serviceAreaIds: serviceAreaIds,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getCalendarJobs({required int month, required int year}) async {
    try {
      return await _jobRepo.getCalendarJobs(month: month, year: year);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getJobs({String? cursor, int limit = 10}) async {
    try {
      return await _jobRepo.getJobs(cursor: cursor, limit: limit);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getAllJobOffers() async {
    try {
      return await _jobRepo.getAllJobOffers();
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> applyToJob({required String jobId}) async {
    try {
      return await _jobRepo.applyToJob(jobId: jobId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getJobById({required String jobId}) async {
    try {
      return await _jobRepo.getJobById(jobId: jobId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> approveApplicant({required String jobId}) async {
    try {
      return await _jobRepo.approveApplicant(jobId: jobId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> rejectApplicant({required String jobId}) async {
    try {
      return await _jobRepo.rejectApplicant(jobId: jobId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateJob({
    required String jobId,
    String? pickupLocation,
    double? paymentAmount,
    String? instruction,
    String? dropoffLocation,
    String? date,
    String? time,
    String? vehicleType,
    String? paymentType,
    String? jobType,
    String? flightNumber,
    String? paymentStatus,
    String? passengerName,
    String? passengerPhone,
    String? dispatchType,
    String? serviceAreaId,
    List<String>? serviceAreaIds,
    List<String>? targetedChauffeurs,
  }) async {
    try {
      return await _jobRepo.updateJob(
        jobId: jobId,
        pickupLocation: pickupLocation,
        paymentAmount: paymentAmount,
        instruction: instruction,
        dropoffLocation: dropoffLocation,
        date: date,
        time: time,
        vehicleType: vehicleType,
        paymentType: paymentType,
        jobType: jobType,
        flightNumber: flightNumber,
        paymentStatus: paymentStatus,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        dispatchType: dispatchType,
        serviceAreaId: serviceAreaId,
        serviceAreaIds: serviceAreaIds,
        targetedChauffeurs: targetedChauffeurs,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> deleteJob({required String jobId}) async {
    try {
      return await _jobRepo.deleteJob(jobId: jobId);
    } catch (e) {
      rethrow;
    }
  }
}
