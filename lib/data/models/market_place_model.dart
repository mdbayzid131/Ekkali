class CursorPagination {
  String? nextCursor;
  bool? hasMore;
  int? limit;

  CursorPagination({this.nextCursor, this.hasMore, this.limit});

  CursorPagination.fromJson(Map<String, dynamic> json) {
    nextCursor = json['nextCursor']?.toString();
    hasMore = json['hasMore'] is bool ? json['hasMore'] : false;
    limit = json['limit'] is int
        ? json['limit']
        : int.tryParse(json['limit']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'nextCursor': nextCursor,
      'hasMore': hasMore,
      'limit': limit,
    };
  }
}

class MarketplaceModel {
  bool? success;
  String? message;
  CursorPagination? cursor;
  List<ItemData>? data;

  MarketplaceModel({
    this.success,
    this.message,
    this.cursor,
    this.data,
  });

  MarketplaceModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];

    cursor = json['cursor'] != null
        ? CursorPagination.fromJson(json['cursor'])
        : null;

    if (json['data'] != null && json['data'] is List) {
      data = <ItemData>[];
      json['data'].forEach((v) {
        if (v is Map<String, dynamic>) {
          data!.add(ItemData.fromJson(v));
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

class ItemData {
  String? id;
  String? title;
  num? price;
  String? condition;
  String? status;
  String? location;
  String? description;
  List<String>? photos;
  User? createdBy;
  String? createdAt;
  String? updatedAt;

  ItemData({
    this.id,
    this.title,
    this.price,
    this.condition,
    this.status,
    this.location,
    this.description,
    this.photos,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  ItemData.fromJson(Map<String, dynamic> json) {
    id = json['_id']?.toString() ?? json['id']?.toString();
    title = json['title']?.toString();
    if (json['price'] != null) {
      price = num.tryParse(json['price'].toString());
    }
    condition = json['condition']?.toString();
    status = json['status']?.toString() ?? 'AVAILABLE';
    location = json['location']?.toString();
    description = json['description']?.toString();
    photos = json['photos'] != null
        ? (json['photos'] as List).map((e) => e.toString()).toList()
        : [];

    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map<String, dynamic>) {
        createdBy = User.fromJson(json['createdBy']);
      } else if (json['createdBy'] is String) {
        createdBy = User(id: json['createdBy'].toString());
      }
    }

    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'price': price,
      'condition': condition,
      'status': status,
      'location': location,
      'description': description,
      'photos': photos,
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class User {
  String? id;
  String? name;
  String? email;
  String? profilePicture;

  User({this.id, this.name, this.email, this.profilePicture});

  User.fromJson(Map<String, dynamic> json) {
    id = json['_id']?.toString() ?? json['id']?.toString();
    name = json['name']?.toString();
    email = json['email']?.toString();
    profilePicture = json['profilePicture']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
    };
  }
}