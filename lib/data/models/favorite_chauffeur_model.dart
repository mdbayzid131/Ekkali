class FavoriteChauffeurModel {
  final String id;
  final String name;
  final String phone;
  final String serviceArea;
  final String company;
  final String companyRole;
  final String profilePicture;
  final double averageRating;
  final int totalReviews;
  final bool isFavorite;

  final List<String> badges;

  FavoriteChauffeurModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.serviceArea,
    required this.company,
    required this.companyRole,
    required this.profilePicture,
    required this.averageRating,
    required this.totalReviews,
    required this.isFavorite,
    this.badges = const [],
  });

  factory FavoriteChauffeurModel.fromJson(Map<String, dynamic> json) {
    final List<String> badgesList = [];
    if (json['badges'] is List) {
      for (var b in json['badges']) {
        if (b != null && b.toString().isNotEmpty) {
          badgesList.add(b.toString());
        }
      }
    }

    return FavoriteChauffeurModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      serviceArea: json['serviceArea'] is Map
          ? (json['serviceArea']['areaName']?.toString() ??
              json['serviceArea']['name']?.toString() ??
              '')
          : (json['serviceArea']?.toString() ?? ''),
      company: json['company']?.toString() ?? json['companyName']?.toString() ?? '',
      companyRole: json['companyRole']?.toString() ?? 'Chauffeur',
      profilePicture: json['profilePicture']?.toString() ?? '',
      averageRating: (json['averageRating'] is num)
          ? (json['averageRating'] as num).toDouble()
          : double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0.0,
      totalReviews: (json['totalReviews'] is int)
          ? json['totalReviews']
          : int.tryParse(json['totalReviews']?.toString() ?? '0') ?? 0,
      isFavorite: json['isFavorite'] == true,
      badges: badgesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'serviceArea': serviceArea,
      'company': company,
      'companyRole': companyRole,
      'profilePicture': profilePicture,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'isFavorite': isFavorite,
      'badges': badges,
    };
  }
}

class FavoriteCursorModel {
  final String? nextCursor;
  final bool hasMore;
  final int limit;

  FavoriteCursorModel({
    this.nextCursor,
    required this.hasMore,
    required this.limit,
  });

  factory FavoriteCursorModel.fromJson(Map<String, dynamic> json) {
    return FavoriteCursorModel(
      nextCursor: json['nextCursor'],
      hasMore: json['hasMore'] == true,
      limit: json['limit'] is int
          ? json['limit']
          : int.tryParse(json['limit']?.toString() ?? '10') ?? 10,
    );
  }
}
