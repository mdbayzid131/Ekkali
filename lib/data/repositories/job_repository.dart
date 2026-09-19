import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class JobRepo {
  final ApiClient apiClient;
  JobRepo({required this.apiClient});

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
    final Map<String, dynamic> body = {
      "jobType": jobType,
      "pickup": pickup,
      "dropoff": dropoff,
      "vehicleType": vehicleType,
      "paymentAmount": paymentAmount,
      "paymentType": paymentType,
      "dispatchType": dispatchType,
      "asap": asap,
    };

    if (!asap) {
      if (date != null && date.isNotEmpty) {
        body["date"] = date;
      }
      if (time != null && time.isNotEmpty) {
        body["time"] = time;
      }
    }

    if (flightNumber != null && flightNumber.isNotEmpty) {
      body["flightNumber"] = flightNumber;
    }
    if (instruction != null && instruction.isNotEmpty) {
      body["instruction"] = instruction;
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      body["paymentStatus"] = paymentStatus;
    }
    if (passengerName != null && passengerName.isNotEmpty) {
      body["passengerName"] = passengerName;
    }
    if (passengerPhone != null && passengerPhone.isNotEmpty) {
      body["passengerPhone"] = passengerPhone;
    }
    if (dispatchType == "TARGETED CHAUFFEURS" && targetedChauffeurs != null) {
      body["targetedChauffeurs"] = targetedChauffeurs;
    } else {
      body["targetedChauffeurs"] = [];
    }
    if (dispatchType == "ALL CHAUFFEURS") {
      if (serviceAreaIds != null && serviceAreaIds.isNotEmpty) {
        body["serviceAreaIds"] = serviceAreaIds;
      } else if (serviceAreaId != null && serviceAreaId.isNotEmpty) {
        body["serviceAreaIds"] = [serviceAreaId];
      }
    }

    return await apiClient.postData(ApiConstants.createJob, body);
  }

  Future<Response> getCalendarJobs({required int month, required int year}) async {
    final Map<String, dynamic> query = {
      'month': month,
      'year': year,
    };
    return await apiClient.getData(ApiConstants.calendarJobs, query: query);
  }

  Future<Response> getJobs({String? cursor, int limit = 10}) async {
    final Map<String, dynamic> query = {'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }
    return await apiClient.getData(
      ApiConstants.myJobs,
      query: query,
    );
  }

  Future<Response> getAllJobOffers() async {
    return await apiClient.getData(
      ApiConstants.getAllJobOffers,
    );
  }

  Future<Response> applyToJob({required String jobId}) async {
    return await apiClient.postData(
      ApiConstants.applytoJob.replaceAll('{jobId}', jobId),
      null,
    );
  }

  Future<Response> getUpcomingJobs({String? cursor, int limit = 10}) async {
    final query = <String, dynamic>{'type': 'upcoming', 'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }
    return await apiClient.getData(
      ApiConstants.myRides,
      query: query,
    );
  }

  Future<Response> getPastJobs({String? cursor, int limit = 10}) async {
    final query = <String, dynamic>{'type': 'past', 'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }
    return await apiClient.getData(
      ApiConstants.myRides,
      query: query,
    );
  }

  Future<Response> rejectApplicant({required String jobId}) async {
    return await apiClient.patchData(
      ApiConstants.rejectApplicant.replaceAll('{jobId}', jobId),
      {},
    );
  }

  Future<Response> approveApplicant({required String jobId}) async {
    return await apiClient.patchData(
      ApiConstants.approveApplicant.replaceAll('{jobId}', jobId),
      {},
    );
  }

  Future<Response> cancelJobOffer({required String jobId}) async {
    return await apiClient.patchData(
      ApiConstants.cancelJobOffer.replaceAll('{jobId}', jobId),
      null,
    );
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
    bool asap = false,
  }) async {
    final Map<String, dynamic> body = {};

    if (pickupLocation != null) body["pickup"] = pickupLocation;
    if (dropoffLocation != null) body["dropoff"] = dropoffLocation;
    if (paymentAmount != null) body["paymentAmount"] = paymentAmount;
    if (instruction != null) body["instruction"] = instruction;
    if (vehicleType != null) body["vehicleType"] = vehicleType;
    if (paymentType != null) body["paymentType"] = paymentType;
    if (jobType != null) body["jobType"] = jobType;

    if (!asap) {
      if (date != null && date.isNotEmpty) {
        body["date"] = date;
      }
      if (time != null && time.isNotEmpty) {
        body["time"] = time;
      }
    }

    if (flightNumber != null && flightNumber.isNotEmpty) {
      body["flightNumber"] = flightNumber;
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      body["paymentStatus"] = paymentStatus;
    }
    if (passengerName != null && passengerName.isNotEmpty) {
      body["passengerName"] = passengerName;
    }
    if (passengerPhone != null && passengerPhone.isNotEmpty) {
      body["passengerPhone"] = passengerPhone;
    }

    if (dispatchType != null && dispatchType.isNotEmpty) {
      body["dispatchType"] = dispatchType;
      if (dispatchType == "ALL CHAUFFEURS") {
        if (serviceAreaIds != null && serviceAreaIds.isNotEmpty) {
          body["serviceAreaIds"] = serviceAreaIds;
          body["serviceAreaId"] = serviceAreaIds.first;
        } else if (serviceAreaId != null && serviceAreaId.isNotEmpty) {
          body["serviceAreaIds"] = [serviceAreaId];
          body["serviceAreaId"] = serviceAreaId;
        }
      } else if (dispatchType == "TARGETED CHAUFFEURS" &&
          targetedChauffeurs != null) {
        body["targetedChauffeurs"] = targetedChauffeurs;
      }
    }

    return await apiClient.patchData(
      ApiConstants.updateJob.replaceAll('{jobId}', jobId),
      body,
    );
  }

  Future<Response> deleteJob({required String jobId}) async {
    return await apiClient.deleteData(
      ApiConstants.updateJob.replaceAll('{jobId}', jobId),
    );
  }

  Future<Response> getJobById({required String jobId}) async {
    return await apiClient.getData(
      ApiConstants.updateJob.replaceAll('{jobId}', jobId),
    );
  }

  Future<Response> updateRideStatus({
    required String jobId,
    required String rideStatus,
  }) async {
    return await apiClient.patchData(
      ApiConstants.updateRideStatus.replaceAll('{jobId}', jobId),
      {"rideStatus": rideStatus},
    );
  }

  Future<Response> submitReview({
    required String jobId,
    required int rating,
    String? comment,
  }) async {
    return await apiClient.postData(
      ApiConstants.jobReview.replaceAll('{jobId}', jobId),
      {
        "rating": rating,
        if (comment != null && comment.isNotEmpty) "comment": comment,
      },
    );
  }
}
