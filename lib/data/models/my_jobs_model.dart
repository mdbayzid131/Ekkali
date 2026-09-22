class MyJobsModel {
  bool? success;
  String? message;
  CursorPagination? cursor;
  List<JobData>? data;

  MyJobsModel({this.success, this.message, this.cursor, this.data});

  MyJobsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    cursor = json['cursor'] != null
        ? CursorPagination.fromJson(json['cursor'])
        : null;

    if (json['data'] != null) {
      data = <JobData>[];
      json['data'].forEach((v) {
        if (v is Map) {
          data!.add(JobData.fromJson(Map<String, dynamic>.from(v)));
        }
      });
    }
  }
}

class CursorPagination {
  String? nextCursor;
  bool? hasMore;
  int? limit;

  CursorPagination({this.nextCursor, this.hasMore, this.limit});

  CursorPagination.fromJson(Map<String, dynamic> json) {
    nextCursor = json['nextCursor']?.toString();
    hasMore = json['hasMore'] is bool ? json['hasMore'] : null;
    limit = json['limit'] != null
        ? (num.tryParse(json['limit'].toString())?.toInt())
        : null;
  }
}

class JobData {
  String? id;
  String? jobType;
  String? pickupLocation;
  String? dropoffLocation;
  String? pickupNotes;
  String? dropoffNotes;
  String? companyName;
  String? flightNumber;
  String? duration;
  bool? asap;
  String? date;
  String? time;
  String? vehicleType;
  int? paymentAmount;
  String? paymentType;
  String? instruction;
  String? serviceArea;
  String? dispatchType;
  String? status;
  String? rideStatus;
  int? applicantCount;
  dynamic createdBy; // Driver object or String
  String? createdAt;
  String? updatedAt;
  bool? hasReview;
  bool? isReviewedByCreator;
  bool? isReviewedByDriver;

  Review? reviewByDriver;
  Review? reviewByCreator;
  Driver? assignedTo;
  Applicant? applicant;

  JobData({
    this.id,
    this.jobType,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupNotes,
    this.dropoffNotes,
    this.flightNumber,
    this.duration,
    this.asap,
    this.date,
    this.time,
    this.vehicleType,
    this.paymentAmount,
    this.paymentType,
    this.instruction,
    this.serviceArea,
    this.dispatchType,
    this.status,
    this.rideStatus,
    this.applicantCount,
    this.createdBy,
    this.companyName,
    this.createdAt,
    this.updatedAt,
    this.reviewByDriver,
    this.reviewByCreator,
    this.assignedTo,
    this.applicant,
    this.hasReview,
    this.isReviewedByCreator,
    this.isReviewedByDriver,
  });

  factory JobData.fromJson(Map<String, dynamic> json) {
    dynamic parsedCreatedBy;
    if (json['createdBy'] is Map) {
      parsedCreatedBy = Driver.fromJson(Map<String, dynamic>.from(json['createdBy']));
    } else {
      parsedCreatedBy = json['createdBy']?.toString();
    }

    String? comp = json['companyName']?.toString();
    if (comp == null || comp.isEmpty) {
      if (parsedCreatedBy is Driver) {
        comp = parsedCreatedBy.company ?? parsedCreatedBy.name;
      }
    }

    return JobData(
      id: json['_id'] ?? json['id'],
      jobType: json['jobType'],
      pickupLocation: json['pickup'] ?? json['pickupLocation'],
      dropoffLocation: json['dropoff'] ?? json['dropoffLocation'],
      pickupNotes: json['pickupNotes'],
      dropoffNotes: json['dropoffNotes'],
      flightNumber: json['flightNumber'],
      duration: json['duration']?.toString(),
      asap: json['asap'] == true,
      date: json['date'],
      time: json['time'],
      vehicleType: json['vehicleType'] ?? json['type'],
      paymentAmount: json['paymentAmount'] != null
          ? (num.tryParse(json['paymentAmount'].toString())?.toInt() ?? 0)
          : null,
      paymentType: json['paymentType'],
      instruction: json['instruction'],
      serviceArea: json['serviceArea'] is Map
          ? (json['serviceArea']['areaName']?.toString() ??
              json['serviceArea']['name']?.toString())
          : json['serviceArea']?.toString(),
      dispatchType: json['dispatchType'],
      status: json['status'],
      rideStatus: json['rideStatus'],
      applicantCount: json['applicantCount'] != null
          ? (num.tryParse(json['applicantCount'].toString())?.toInt() ?? 0)
          : 0,
      hasReview: json['hasReview'],
      isReviewedByCreator: json['isReviewedByCreator'],
      isReviewedByDriver: json['isReviewedByDriver'],
      createdBy: parsedCreatedBy,
      companyName: comp,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      reviewByDriver: json['reviewByDriver'] != null
          ? Review.fromJson(Map<String, dynamic>.from(json['reviewByDriver']))
          : null,
      reviewByCreator: json['reviewByCreator'] != null
          ? Review.fromJson(Map<String, dynamic>.from(json['reviewByCreator']))
          : null,
      assignedTo: json['assignedTo'] != null
          ? Driver.fromJson(Map<String, dynamic>.from(json['assignedTo']))
          : null,
      applicant: json['applicant'] != null
          ? Applicant.fromJson(Map<String, dynamic>.from(json['applicant']))
          : null,
    );
  }
}

class Driver {
  String? id;
  String? name;
  String? email;
  String? phone;
  String? company;
  String? companyRole;
  String? profilePicture;
  String? nickname;
  dynamic selectedVehicle;
  List<Vehicle>? vehicles;
  double? averageRating;
  int? totalReviews;

  Driver({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.company,
    this.companyRole,
    this.profilePicture,
    this.nickname,
    this.selectedVehicle,
    this.vehicles,
    this.averageRating,
    this.totalReviews,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    String? comp;
    if (json['company'] is Map) {
      comp = json['company']['name']?.toString() ?? json['company']['companyName']?.toString();
    } else if (json['company'] != null) {
      comp = json['company'].toString();
    } else if (json['companyName'] != null) {
      comp = json['companyName'].toString();
    }

    return Driver(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      company: comp,
      companyRole: json['companyRole'],
      profilePicture: json['profilePicture'],
      nickname: json['nickname'],
      selectedVehicle: json['selectedVehicle'],
      averageRating: (json['averageRating'] is num)
          ? (json['averageRating'] as num).toDouble()
          : double.tryParse(json['averageRating']?.toString() ?? ''),
      totalReviews: (json['totalReviews'] is num)
          ? (json['totalReviews'] as num).toInt()
          : int.tryParse(json['totalReviews']?.toString() ?? ''),
      vehicles: json['vehicles'] != null && json['vehicles'] is List
          ? (json['vehicles'] as List)
              .map((v) => v is Map ? Vehicle.fromJson(Map<String, dynamic>.from(v)) : null)
              .whereType<Vehicle>()
              .toList()
          : null,
    );
  }
}

class Review {
  int? rating;
  String? comment;
  String? reviewedAt;

  Review({this.rating, this.comment, this.reviewedAt});

  Review.fromJson(Map<String, dynamic> json) {
    rating = json['rating'] != null ? num.tryParse(json['rating'].toString())?.toInt() : null;
    comment = json['comment']?.toString();
    reviewedAt = json['reviewedAt']?.toString();
  }
}

class Applicant {
  Driver? driver;
  String? appliedAt;

  Applicant({this.driver, this.appliedAt});

  Applicant.fromJson(Map<String, dynamic> json) {
    if (json['driver'] != null && json['driver'] is Map) {
      driver = Driver.fromJson(Map<String, dynamic>.from(json['driver']));
    } else if (json['name'] != null || json['_id'] != null) {
      driver = Driver.fromJson(json);
    }
    appliedAt = json['appliedAt']?.toString();
  }
}

class Vehicle {
  String? id;
  String? carType;
  String? make;
  String? model;
  String? colorInside;
  String? colorOutside;
  int? year;
  String? licensePlate;

  Vehicle({
    this.id,
    this.carType,
    this.make,
    this.model,
    this.colorInside,
    this.colorOutside,
    this.year,
    this.licensePlate,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] ?? json['id'],
      carType: json['carType'] ?? json['vehicleType'],
      make: json['make'],
      model: json['model'],
      colorInside: json['colorInside'],
      colorOutside: json['colorOutside'],
      year: json['year'] != null ? num.tryParse(json['year'].toString())?.toInt() : null,
      licensePlate: json['licensePlate'],
    );
  }
}
