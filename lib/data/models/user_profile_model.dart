class UserProfileModel {
  final String id;
  final String name;
  final String role;
  final String email;
  final String phone;
  final String home;
  final String serviceArea;
  final int experience;
  final String company;
  final String companyRole;
  final String profilePicture;
  final String status;
  final bool verified;
  final List<String> badges;
  final List<String> deviceTokens;
  final List<Vehicle> vehicles;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double averageRating;
  final String? selectedVehicle;
  final String? nickname;
  final String? uid;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.home,
    required this.serviceArea,
    required this.experience,
    required this.company,
    required this.companyRole,
    required this.profilePicture,
    required this.status,
    required this.verified,
    this.badges = const [],
    required this.deviceTokens,
    required this.vehicles,
    required this.createdAt,
    required this.updatedAt,
    this.averageRating = 0.0,
    this.selectedVehicle,
    this.nickname,
    this.uid,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final List<String> badgesList = [];
    if (json['badges'] is List) {
      for (var b in json['badges']) {
        if (b != null && b.toString().isNotEmpty) {
          badgesList.add(b.toString());
        }
      }
    } else if (json['badge'] != null && json['badge'].toString().isNotEmpty) {
      badgesList.add(json['badge'].toString());
    }

    return UserProfileModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      home: json['home']?.toString() ?? '',
      serviceArea: json['serviceArea'] is Map
          ? (json['serviceArea']['areaName']?.toString() ??
              json['serviceArea']['name']?.toString() ??
              '')
          : (json['serviceArea']?.toString() ?? ''),
      experience: json['experience'] is int ? json['experience'] : 0,
      company: json['company']?.toString() ?? '',
      companyRole: json['companyRole']?.toString() ?? '',
      profilePicture: json['profilePicture']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      verified: json['verified'] ?? false,
      badges: badgesList,
      deviceTokens:
          (json['deviceTokens'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      vehicles:
          (json['vehicles'] as List?)
              ?.map((e) => Vehicle.fromJson(e))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      selectedVehicle: json['selectedVehicle'] is Map
          ? (json['selectedVehicle']['id']?.toString() ??
              json['selectedVehicle']['_id']?.toString())
          : json['selectedVehicle']?.toString(),
      nickname: json['nickname']?.toString(),
      uid: json['uid']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
      'home': home,
      'serviceArea': serviceArea,
      'experience': experience,
      'company': company,
      'companyRole': companyRole,
      'profilePicture': profilePicture,
      'status': status,
      'verified': verified,
      'badges': badges,
      'deviceTokens': deviceTokens,
      'vehicles': vehicles.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'averageRating': averageRating,
      'selectedVehicle': selectedVehicle,
      'nickname': nickname,
      'uid': uid,
    };
  }
}

class Vehicle {
  final String id;
  final String carType;
  final String make;
  final String model;
  final String makeAndModel;
  final String colorInside;
  final String colorOutside;
  final int year;
  final String licensePlate;
  final String status;
  final String? rejectionReason;
  final String? vehicleRegistrationImage;
  final String? vehicleRegistrationExpiryDate;
  final String? commercialInsuranceImage;
  final String? commercialInsuranceExpiryDate;
  final String? vehiclePhotoFront;
  final String? vehiclePhotoRear;
  final String? vehiclePhotoInterior;

  Vehicle({
    required this.id,
    required this.carType,
    required this.make,
    required this.model,
    required this.makeAndModel,
    required this.colorInside,
    required this.colorOutside,
    required this.year,
    required this.licensePlate,
    this.status = 'PENDING_REVIEW',
    this.rejectionReason,
    this.vehicleRegistrationImage,
    this.vehicleRegistrationExpiryDate,
    this.commercialInsuranceImage,
    this.commercialInsuranceExpiryDate,
    this.vehiclePhotoFront,
    this.vehiclePhotoRear,
    this.vehiclePhotoInterior,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final rawMakeAndModel = json['makeAndModel']?.toString() ??
        '${json['make'] ?? ''} ${json['model'] ?? ''}'.trim();
    
    String parsedMake = json['make']?.toString() ?? '';
    String parsedModel = json['model']?.toString() ?? '';

    if (parsedMake.isEmpty && rawMakeAndModel.isNotEmpty) {
      final parts = rawMakeAndModel.split(' ');
      parsedMake = parts.first;
      parsedModel = parts.skip(1).join(' ');
    }

    final rawType = json['type']?.toString() ?? json['carType']?.toString() ?? 'Sedan';

    return Vehicle(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      carType: rawType,
      make: parsedMake,
      model: parsedModel,
      makeAndModel: rawMakeAndModel.isNotEmpty ? rawMakeAndModel : "$parsedMake $parsedModel".trim(),
      colorInside: json['colorInside']?.toString() ?? '',
      colorOutside: json['colorOutside']?.toString() ?? '',
      year: json['year'] is int
          ? json['year']
          : (int.tryParse(json['year']?.toString() ?? '') ?? 0),
      licensePlate: json['licensePlate']?.toString() ?? json['licensePlateRaw']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING_REVIEW',
      rejectionReason: json['rejectionReason']?.toString(),
      // Nested: vehicleRegistration.image / .expiryDate
      vehicleRegistrationImage: json['vehicleRegistration'] is Map
          ? json['vehicleRegistration']['image']?.toString()
          : json['vehicleRegistrationImage']?.toString(),
      vehicleRegistrationExpiryDate: json['vehicleRegistration'] is Map
          ? json['vehicleRegistration']['expiryDate']?.toString()
          : json['vehicleRegistrationExpiryDate']?.toString(),
      // Nested: commercialInsurance.image / .expiryDate
      commercialInsuranceImage: json['commercialInsurance'] is Map
          ? json['commercialInsurance']['image']?.toString()
          : json['commercialInsuranceImage']?.toString(),
      commercialInsuranceExpiryDate: json['commercialInsurance'] is Map
          ? json['commercialInsurance']['expiryDate']?.toString()
          : json['commercialInsuranceExpiryDate']?.toString(),
      // Nested: photos.frontView / .rearView / .interiorView
      vehiclePhotoFront: json['photos'] is Map
          ? json['photos']['frontView']?.toString()
          : json['vehiclePhotoFront']?.toString(),
      vehiclePhotoRear: json['photos'] is Map
          ? json['photos']['rearView']?.toString()
          : json['vehiclePhotoRear']?.toString(),
      vehiclePhotoInterior: json['photos'] is Map
          ? json['photos']['interiorView']?.toString()
          : json['vehiclePhotoInterior']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'type': carType,
      'carType': carType,
      'make': make,
      'model': model,
      'makeAndModel': makeAndModel,
      'colorInside': colorInside,
      'colorOutside': colorOutside,
      'year': year,
      'licensePlate': licensePlate,
      'status': status,
      'rejectionReason': rejectionReason,
      'vehicleRegistrationImage': vehicleRegistrationImage,
      'vehicleRegistrationExpiryDate': vehicleRegistrationExpiryDate,
      'commercialInsuranceImage': commercialInsuranceImage,
      'commercialInsuranceExpiryDate': commercialInsuranceExpiryDate,
      'vehiclePhotoFront': vehiclePhotoFront,
      'vehiclePhotoRear': vehiclePhotoRear,
      'vehiclePhotoInterior': vehiclePhotoInterior,
    };
  }
}
