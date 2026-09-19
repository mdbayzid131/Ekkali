class VehicleConfigOption {
  final String id;
  final String vehicleType;
  final int maxAge;
  final List<String> allowedColors;
  final List<String> makesAndModels;

  VehicleConfigOption({
    required this.id,
    required this.vehicleType,
    required this.maxAge,
    required this.allowedColors,
    required this.makesAndModels,
  });

  factory VehicleConfigOption.fromJson(Map<String, dynamic> json) {
    return VehicleConfigOption(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
      maxAge: json['maxAge'] is int
          ? json['maxAge'] as int
          : (int.tryParse(json['maxAge']?.toString() ?? '5') ?? 5),
      allowedColors: (json['allowedColors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Black'],
      makesAndModels: (json['makesAndModels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vehicleType': vehicleType,
      'maxAge': maxAge,
      'allowedColors': allowedColors,
      'makesAndModels': makesAndModels,
    };
  }
}
