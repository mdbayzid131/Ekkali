class JobOfferModel {
  final String id;
  final String bookingNo;
  final String jobType;
  final String pickup;
  final String dropoff;
  final String? pickupNotes;
  final String? dropoffNotes;
  final bool asap;
  final DateTime? date;
  final String? time;
  final String vehicleType;
  final double paymentAmount;
  final String paymentType;
  final String status;
  final String? rideStatus;
  final String companyName;
  final String passengerName;
  final String? instruction;
  final String? flightNumber;
  final String? duration;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JobOfferModel({
    required this.id,
    required this.bookingNo,
    required this.jobType,
    required this.pickup,
    required this.dropoff,
    this.pickupNotes,
    this.dropoffNotes,
    this.asap = false,
    this.date,
    this.time,
    required this.vehicleType,
    required this.paymentAmount,
    required this.paymentType,
    required this.status,
    this.rideStatus,
    required this.companyName,
    required this.passengerName,
    this.instruction,
    this.flightNumber,
    this.duration,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  String get displayTime {
    if (asap) return 'ASAP';
    if (time != null && time!.isNotEmpty) return time!;
    return 'ASAP';
  }

  factory JobOfferModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final rawBookingNo =
        json['bookingNo']?.toString() ??
        (rawId.length >= 6
            ? 'OFFER-${rawId.substring(rawId.length - 6).toUpperCase()}'
            : 'OFFER-$rawId');

    final bool isAsap = json['asap'] == true;

    DateTime? parsedDate;
    if (!isAsap && json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString());
    }

    String? parsedTime;
    if (!isAsap && json['time'] != null) {
      parsedTime = json['time'].toString();
    }

    double parsedAmount = 0.0;
    if (json['paymentAmount'] != null) {
      parsedAmount = (json['paymentAmount'] is num)
          ? (json['paymentAmount'] as num).toDouble()
          : double.tryParse(json['paymentAmount'].toString()) ?? 0.0;
    } else if (json['price'] != null) {
      parsedAmount = (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0;
    }

    return JobOfferModel(
      id: rawId,
      bookingNo: rawBookingNo,
      jobType: json['jobType']?.toString() ?? 'ONE WAY',
      pickup:
          json['pickup']?.toString() ??
          json['pickupLocation']?.toString() ??
          '',
      dropoff:
          json['dropoff']?.toString() ??
          json['dropoffLocation']?.toString() ??
          '',
      pickupNotes: json['pickupNotes']?.toString(),
      dropoffNotes: json['dropoffNotes']?.toString(),
      asap: isAsap,
      date: parsedDate,
      time: parsedTime,
      vehicleType:
          json['vehicleType']?.toString() ??
          json['type']?.toString() ??
          'Sedan',
      paymentAmount: parsedAmount,
      paymentType:
          json['paymentType']?.toString() ??
          json['payment']?.toString() ??
          'CREDIT CARD ON FILE',
      status: json['status']?.toString() ?? 'PENDING',
      rideStatus: json['rideStatus']?.toString(),
      companyName:
          json['companyName']?.toString() ?? json['company']?.toString() ?? '',
      passengerName:
          json['passengerName']?.toString() ??
          json['passenger']?.toString() ??
          'Client',
      instruction:
          json['instruction']?.toString() ??
          json['instructions']?.toString() ??
          json['specialInstructions']?.toString(),
      flightNumber:
          json['flightNumber']?.toString() ?? json['flight']?.toString(),
      duration: json['duration']?.toString(),
      createdBy: (json['createdBy'] is Map)
          ? (json['createdBy']['id'] ?? json['createdBy']['_id'])?.toString()
          : (json['createdBy'] ??
                    json['userId'] ??
                    (json['user'] is Map
                        ? (json['user']['id'] ?? json['user']['_id'])
                        : json['user']) ??
                    json['creator'])
                ?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'bookingNo': bookingNo,
      'jobType': jobType,
      'pickup': pickup,
      'pickupLocation': pickup,
      'dropoff': dropoff,
      'dropoffLocation': dropoff,
      'pickupNotes': pickupNotes,
      'dropoffNotes': dropoffNotes,
      'asap': asap,
      'date': date?.toIso8601String(),
      'time': time ?? (asap ? 'ASAP' : ''),
      'vehicleType': vehicleType,
      'type': vehicleType,
      'paymentAmount': paymentAmount,
      'price': paymentAmount.toStringAsFixed(2),
      'paymentType': paymentType,
      'payment': paymentType,
      'status': status,
      'rideStatus': rideStatus,
      'companyName': companyName,
      'company': companyName,
      'passengerName': passengerName,
      'passenger': passengerName,
      'instruction': instruction,
      'instructions': instruction,
      'flightNumber': flightNumber,
      'flight': flightNumber,
      'createdBy': createdBy,
    };
  }
}
