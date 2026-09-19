import 'market_place_model.dart';

class MyItemsResponse {
  bool? success;
  String? message;
  CursorPagination? cursor;
  List<MyItemsModel>? data;

  MyItemsResponse({
    this.success,
    this.message,
    this.cursor,
    this.data,
  });

  MyItemsResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];

    cursor = json['cursor'] != null
        ? CursorPagination.fromJson(json['cursor'])
        : null;

    if (json['data'] != null && json['data'] is List) {
      data = <MyItemsModel>[];
      json['data'].forEach((v) {
        if (v is Map<String, dynamic>) {
          data!.add(MyItemsModel.fromJson(v));
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'cursor': cursor?.toJson(),
      'data': data?.map((v) => v.toJson()).toList(),
    };
  }
}

class MyItemsModel {
  final String id;
  final String name;
  final String price;
  final double rating;
  final String imagePath;
  final String condition;
  final String status;
  final String location;
  final String description;
  final List<String> photos;
  final DateTime createdAt;

  MyItemsModel({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.imagePath,
    required this.condition,
    required this.status,
    required this.location,
    required this.description,
    required this.photos,
    required this.createdAt,
  });

  factory MyItemsModel.fromJson(Map<String, dynamic> json) {
    List<String> photosList =
        (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? [];
    String firstPhoto = photosList.isNotEmpty ? photosList[0] : '';

    return MyItemsModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['title']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      rating: 5.0,
      imagePath: firstPhoto,
      condition: json['condition']?.toString() ?? '',
      status: json['status']?.toString() ?? 'AVAILABLE',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      photos: photosList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': name,
      'price': price,
      'condition': condition,
      'status': status,
      'location': location,
      'description': description,
      'photos': photos,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ItemData toItemData() {
    return ItemData(
      id: id,
      title: name,
      price: num.tryParse(price) ?? 0,
      condition: condition,
      status: status,
      location: location,
      description: description,
      photos: photos,
      createdAt: createdAt.toIso8601String(),
    );
  }
}
