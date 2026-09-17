class JobResponse {
  final bool success;
  final String message;
  final Pagination? pagination;
  final List<Job> data;

  JobResponse({
    required this.success,
    required this.message,
    this.pagination,
    required this.data,
  });

  factory JobResponse.fromJson(Map<String, dynamic> json) {
    return JobResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      data: json['data'] != null
          ? (json['data'] as List)
                .map((x) {
                  try {
                    return Job.fromJson(x);
                  } catch (e, stacktrace) {
                    print("Error parsing an individual job: $e");
                    print(stacktrace);
                    return null;
                  }
                })
                .where((job) => job != null)
                .cast<Job>()
                .toList()
          : [],
    );
  }
}

class Pagination {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  Pagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 0,
      page: json['page'] ?? 0,
      totalPage: json['totalPage'] ?? 0,
    );
  }
}

class Job {
  final String id;
  final String jobType;
  final String pickupLocation;
  final String? dropoffLocation;
  final String? flightNumber;
  final bool? asap;
  final DateTime? date;
  final String time;
  final String vehicleType;
  final num paymentAmount;
  final String paymentType;
  final String? instruction;
  final String status;
  final CreatedBy? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Job({
    required this.id,
    required this.jobType,
    required this.pickupLocation,
    this.dropoffLocation,
    this.flightNumber,
    this.asap,
    this.date,
    required this.time,
    required this.vehicleType,
    required this.paymentAmount,
    required this.paymentType,
    this.instruction,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id'] ?? json['id'] ?? '',
      jobType: json['jobType'] ?? '',
      pickupLocation: json['pickup'] ?? json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoff'] ?? json['dropoffLocation'],
      flightNumber: json['flightNumber'],
      asap: json['asap'],
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      time: json['time'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      paymentAmount: json['paymentAmount'] != null
          ? num.tryParse(json['paymentAmount'].toString()) ?? 0
          : 0,
      paymentType: json['paymentType'] ?? '',
      instruction: json['instruction'],
      status: json['status'] ?? '',
      createdBy:
          (json['createdBy'] != null &&
              json['createdBy'] is Map<String, dynamic>)
          ? CreatedBy.fromJson(json['createdBy'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class CreatedBy {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profilePicture;
  final String nickname;
  final String company;
  final String? companyRole;
  final dynamic selectedVehicle;
  final double? averageRating;
  final int? totalReviews;

  CreatedBy({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profilePicture,
    required this.nickname,
    required this.company,
    this.companyRole,
    this.selectedVehicle,
    this.averageRating,
    this.totalReviews,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    String compName = '';
    if (json['company'] is Map) {
      compName = json['company']['name']?.toString() ??
          json['company']['companyName']?.toString() ??
          '';
    } else if (json['company'] is String) {
      compName = json['company'];
    } else if (json['companyName'] != null) {
      compName = json['companyName'].toString();
    }

    return CreatedBy(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profilePicture: json['profilePicture']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      company: compName,
      companyRole: json['companyRole']?.toString(),
      selectedVehicle: json['selectedVehicle'],
      averageRating: (json['averageRating'] is num)
          ? (json['averageRating'] as num).toDouble()
          : double.tryParse(json['averageRating']?.toString() ?? ''),
      totalReviews: (json['totalReviews'] is num)
          ? (json['totalReviews'] as num).toInt()
          : int.tryParse(json['totalReviews']?.toString() ?? ''),
    );
  }
}
