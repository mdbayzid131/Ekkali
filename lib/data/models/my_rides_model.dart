import 'package:moeb_26/data/models/user_profile_model.dart';

class MyRidesModel {
  final bool success;
  final String message;
  final CursorPagination? cursor;
  final List<RideData> data;

  MyRidesModel({
    required this.success,
    required this.message,
    this.cursor,
    required this.data,
  });

  factory MyRidesModel.fromJson(Map<String, dynamic> json) {
    return MyRidesModel(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      cursor: json['cursor'] is Map<String, dynamic>
          ? CursorPagination.fromJson(json['cursor'])
          : null,
      data: (json['data'] as List?)
              ?.map((x) => RideData.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'cursor': cursor?.toJson(),
      'data': data.map((v) => v.toJson()).toList(),
    };
  }
}

class CursorPagination {
  final String? nextCursor;
  final bool hasMore;
  final int limit;

  CursorPagination({
    this.nextCursor,
    this.hasMore = false,
    this.limit = 10,
  });

  factory CursorPagination.fromJson(Map<String, dynamic> json) {
    return CursorPagination(
      nextCursor: json['nextCursor']?.toString(),
      hasMore: json['hasMore'] == true,
      limit: (json['limit'] is num) ? (json['limit'] as num).toInt() : 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nextCursor': nextCursor,
      'hasMore': hasMore,
      'limit': limit,
    };
  }
}

class RideData {
  final String id;
  final String? jobCreatorId;
  final String? jobType;
  final String pickupLocation;
  final String dropoffLocation;
  final String? flightNumber;
  final bool asap;
  final String? date;
  final String? time;
  final String vehicleType;
  final num? paymentAmount;
  final String? paymentType;
  final String? instruction;
  final String? passengerName;
  final String? passengerPhone;
  final String? status;
  final String? rideStatus;
  final String? name;
  final String? nickname;
  final String? company;
  final String? companyName;
  final String? companyRole;
  final String? profilePicture;
  final bool hasReview;
  final bool isReviewedByDriver;
  final bool isReviewedByCreator;
  final String? createdAt;
  final String? updatedAt;
  final DriverData? createdBy;
  final DriverData? assignedTo;
  final ApplicantData? applicant;

  RideData({
    required this.id,
    this.jobCreatorId,
    this.jobType,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.flightNumber,
    this.asap = false,
    this.date,
    this.time,
    required this.vehicleType,
    this.paymentAmount,
    this.paymentType,
    this.instruction,
    this.passengerName,
    this.passengerPhone,
    this.status,
    this.rideStatus,
    this.name,
    this.nickname,
    this.company,
    this.companyName,
    this.companyRole,
    this.profilePicture,
    this.hasReview = false,
    this.isReviewedByDriver = false,
    this.isReviewedByCreator = false,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.assignedTo,
    this.applicant,
  });

  factory RideData.fromJson(Map<String, dynamic> json) {
    DriverData? parseDriver(dynamic field) {
      if (field is Map<String, dynamic>) {
        return DriverData.fromJson(field);
      }
      return null;
    }

    final creatorId = json['jobCreatorId']?.toString() ??
        json['creatorId']?.toString() ??
        (json['createdBy'] is String ? json['createdBy']?.toString() : null);

    return RideData(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      jobCreatorId: creatorId,
      jobType: json['jobType']?.toString(),
      pickupLocation: json['pickup']?.toString() ??
          json['pickupLocation']?.toString() ??
          '',
      dropoffLocation: json['dropoff']?.toString() ??
          json['dropoffLocation']?.toString() ??
          '',
      flightNumber: json['flightNumber']?.toString(),
      asap: json['asap'] == true,
      date: json['date']?.toString(),
      time: json['time']?.toString(),
      vehicleType: json['vehicleType']?.toString() ?? 'Sedan',
      paymentAmount: json['paymentAmount'] is num
          ? (json['paymentAmount'] as num)
          : num.tryParse(json['paymentAmount']?.toString() ?? ''),
      paymentType: json['paymentType']?.toString(),
      instruction: json['instruction']?.toString() ??
          json['instructions']?.toString(),
      passengerName: json['passengerName']?.toString(),
      passengerPhone: json['passengerPhone']?.toString(),
      status: json['status']?.toString(),
      rideStatus: json['rideStatus']?.toString(),
      name: json['name']?.toString(),
      nickname: json['nickname']?.toString(),
      company: json['company']?.toString(),
      companyName: json['companyName']?.toString() ?? json['company']?.toString(),
      companyRole: json['companyRole']?.toString(),
      profilePicture: json['profilePicture']?.toString(),
      hasReview: json['hasReview'] == true,
      isReviewedByDriver: json['isReviewedByDriver'] == true,
      isReviewedByCreator: json['isReviewedByCreator'] == true,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      createdBy: parseDriver(json['createdBy']) ??
          (creatorId != null
              ? DriverData(
                  id: creatorId,
                  name: json['name']?.toString() ?? '',
                  nickname: json['nickname']?.toString(),
                  email: json['email']?.toString() ?? '',
                  phone: json['phone']?.toString() ?? '',
                  company: json['company']?.toString(),
                  profilePicture: json['profilePicture']?.toString() ?? '',
                )
              : null),
      assignedTo: parseDriver(json['assignedTo']),
      applicant: json['applicant'] is Map<String, dynamic>
          ? ApplicantData.fromJson(json['applicant'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'jobCreatorId': jobCreatorId,
      'jobType': jobType,
      'pickup': pickupLocation,
      'dropoff': dropoffLocation,
      'flightNumber': flightNumber,
      'asap': asap,
      'date': date,
      'time': time,
      'vehicleType': vehicleType,
      'paymentAmount': paymentAmount,
      'paymentType': paymentType,
      'instruction': instruction,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'status': status,
      'rideStatus': rideStatus,
      'name': name,
      'nickname': nickname,
      'company': company,
      'companyName': companyName,
      'companyRole': companyRole,
      'profilePicture': profilePicture,
      'hasReview': hasReview,
      'isReviewedByDriver': isReviewedByDriver,
      'isReviewedByCreator': isReviewedByCreator,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class DriverData {
  final String id;
  final String name;
  final String? nickname;
  final String email;
  final String phone;
  final String? company;
  final String? companyRole;
  final String profilePicture;
  final String? selectedVehicle;
  final double? averageRating;
  final int? totalReviews;
  final List<Vehicle>? vehicles;

  DriverData({
    required this.id,
    required this.name,
    this.nickname,
    this.email = '',
    this.phone = '',
    this.company,
    this.companyRole,
    this.profilePicture = '',
    this.selectedVehicle,
    this.averageRating,
    this.totalReviews,
    this.vehicles,
  });

  factory DriverData.fromJson(Map<String, dynamic> json) {
    List<Vehicle>? vehicleList;
    if (json['vehicles'] is List) {
      vehicleList = (json['vehicles'] as List)
          .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    return DriverData(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      company: json['company']?.toString(),
      companyRole: json['companyRole']?.toString(),
      profilePicture: json['profilePicture']?.toString() ?? '',
      selectedVehicle: json['selectedVehicle']?.toString(),
      averageRating: json['averageRating'] is num
          ? (json['averageRating'] as num).toDouble()
          : null,
      totalReviews: json['totalReviews'] is num
          ? (json['totalReviews'] as num).toInt()
          : null,
      vehicles: vehicleList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'nickname': nickname,
      'email': email,
      'phone': phone,
      'company': company,
      'companyRole': companyRole,
      'profilePicture': profilePicture,
      'selectedVehicle': selectedVehicle,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }
}

class ApplicantData {
  final DriverData? driver;
  final String? vehicleId;
  final DateTime? appliedAt;

  ApplicantData({
    this.driver,
    this.vehicleId,
    this.appliedAt,
  });

  factory ApplicantData.fromJson(Map<String, dynamic> json) {
    return ApplicantData(
      driver: json['driver'] is Map<String, dynamic>
          ? DriverData.fromJson(json['driver'])
          : null,
      vehicleId: json['vehicleId']?.toString(),
      appliedAt: json['appliedAt'] != null
          ? DateTime.tryParse(json['appliedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver': driver?.toJson(),
      'vehicleId': vehicleId,
      'appliedAt': appliedAt?.toIso8601String(),
    };
  }
}

// Aliases for compatibility
typedef Ride = RideData;
typedef Driver = DriverData;
typedef Applicant = ApplicantData;
typedef MyRidesResponse = MyRidesModel;
typedef UpcomingRideData = RideData;
typedef FinishRideData = RideData;
typedef UpcomingRidesModel = MyRidesModel;
typedef FinishRidesModel = MyRidesModel;
