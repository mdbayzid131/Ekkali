class MyScheduleJobModel {
  final String id;
  final String clientName;
  final String clientPhone;
  final DateTime pickupDateTime;
  final String pickupLocation;
  final String dropoffLocation;
  final String vehicleType; // e.g. Sedan, SUV, Executive
  final String fare;
  final String notes;
  final String? flightNumber;
  bool isDispatchedToNetwork;
  String status; // e.g. "Scheduled", "Dispatched", "Completed", "Cancelled"
  bool isPaid;
  String? assignedChauffeurId;
  String? assignedChauffeurName;
  String paymentMethod; // e.g. Credit Card, Cash, Zelle, Venmo, Invoice
  String paymentInfo; // Optional client payment details or account notes

  MyScheduleJobModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.pickupDateTime,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.vehicleType,
    this.fare = "",
    this.notes = "",
    this.flightNumber,
    this.isDispatchedToNetwork = false,
    this.status = "Scheduled",
    this.isPaid = false,
    this.assignedChauffeurId,
    this.assignedChauffeurName,
    this.paymentMethod = "Cash / Direct",
    this.paymentInfo = "",
  });

  MyScheduleJobModel copyWith({
    String? id,
    String? clientName,
    String? clientPhone,
    DateTime? pickupDateTime,
    String? pickupLocation,
    String? dropoffLocation,
    String? vehicleType,
    String? fare,
    String? notes,
    String? flightNumber,
    bool? isDispatchedToNetwork,
    String? status,
    bool? isPaid,
    String? assignedChauffeurId,
    String? assignedChauffeurName,
    String? paymentMethod,
    String? paymentInfo,
  }) {
    return MyScheduleJobModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      pickupDateTime: pickupDateTime ?? this.pickupDateTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      vehicleType: vehicleType ?? this.vehicleType,
      fare: fare ?? this.fare,
      notes: notes ?? this.notes,
      flightNumber: flightNumber ?? this.flightNumber,
      isDispatchedToNetwork:
          isDispatchedToNetwork ?? this.isDispatchedToNetwork,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      assignedChauffeurId: assignedChauffeurId ?? this.assignedChauffeurId,
      assignedChauffeurName:
          assignedChauffeurName ?? this.assignedChauffeurName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }

  factory MyScheduleJobModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDateTime = DateTime.now();
    if (json['date'] != null) {
      final dateStr = json['date'].toString();
      final datePart = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;
      final dateParts = datePart.split('-');
      if (dateParts.length >= 3) {
        final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
        final month = int.tryParse(dateParts[1]) ?? DateTime.now().month;
        final day = int.tryParse(dateParts[2]) ?? DateTime.now().day;

        int hour = 0;
        int minute = 0;
        if (json['time'] != null && json['time'].toString().isNotEmpty) {
          final timeParts = json['time'].toString().split(':');
          if (timeParts.length >= 2) {
            hour = int.tryParse(timeParts[0]) ?? 0;
            minute = int.tryParse(timeParts[1]) ?? 0;
          }
        }
        parsedDateTime = DateTime(year, month, day, hour, minute);
      } else {
        final dt = DateTime.tryParse(dateStr);
        if (dt != null) {
          parsedDateTime = dt;
        }
      }
    }

    final createdBy = json['createdBy'];
    String name = json['passengerName'] ?? '';
    if (name.isEmpty && createdBy is Map) {
      name = createdBy['name'] ?? '';
    }

    String phone = json['passengerPhone'] ?? '';
    if (phone.isEmpty && createdBy is Map) {
      phone = createdBy['phone'] ?? '';
    }

    final num fareVal = json['paymentAmount'] ?? 0;
    final String fareStr = '\$${fareVal.toStringAsFixed(2)}';
    final String pStatus =
        json['paymentStatus']?.toString().toUpperCase() ?? 'UNPAID';
    final String dType =
        json['dispatchType']?.toString().toUpperCase() ?? 'PERSONAL NOTE';
    final bool isDispatched =
        dType == 'ALL CHAUFFEURS' || dType == 'TARGETED CHAUFFEURS';

    final String? rawFlight = json['flightNumber']?.toString() ??
        json['flight_number']?.toString() ??
        json['flightNo']?.toString() ??
        json['flight']?.toString();
    final String? cleanFlight = (rawFlight != null &&
            rawFlight.trim().isNotEmpty &&
            rawFlight.trim().toLowerCase() != 'null')
        ? rawFlight.trim()
        : null;

    return MyScheduleJobModel(
      id: json['_id'] ?? '',
      clientName: name,
      clientPhone: phone,
      pickupDateTime: parsedDateTime,
      pickupLocation: json['pickup'] ?? '',
      dropoffLocation: json['dropoff'] ?? '',
      vehicleType: json['vehicleType'] ?? 'Sedan',
      fare: fareStr,
      notes: json['instruction'] ?? '',
      flightNumber: cleanFlight,
      isDispatchedToNetwork: isDispatched,
      status: json['status'] ?? 'Scheduled',
      isPaid: pStatus == 'PAID',
      paymentMethod: json['paymentType'] ?? 'CREDIT CARD ON FILE',
    );
  }
}
