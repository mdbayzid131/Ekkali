class RatingsModel {
  final ReviewSummary reviewSummary;
  final List<Review> reviews;

  RatingsModel({required this.reviewSummary, required this.reviews});

  factory RatingsModel.fromJson(Map<String, dynamic> json) {
    return RatingsModel(
      reviewSummary: ReviewSummary.fromJson(json['reviewSummary'] ?? {}),
      reviews:
          (json['reviews'] as List?)?.map((e) => Review.fromJson(e)).toList() ??
          [],
    );
  }
}

class ReviewSummary {
  final double averageRating;
  final int totalReviews;

  ReviewSummary({required this.averageRating, required this.totalReviews});

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }
}

class Review {
  final String id;
  final String reviewerId;
  final int rating;
  final String comment;
  final String reviewerName;
  final String reviewerImage;
  final DateTime createdAt;
  final String? jobId;

  Review({
    required this.id,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.reviewerName,
    required this.reviewerImage,
    required this.createdAt,
    this.jobId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id']?.toString() ?? json['jobId']?.toString() ?? '',
      reviewerId: json['reviewer']?['_id']?.toString() ??
          json['reviewer']?['id']?.toString() ??
          '',
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toInt()
          : int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      comment: json['comment']?.toString() ?? '',
      reviewerName: json['reviewer']?['name']?.toString() ?? 'User',
      reviewerImage: json['reviewer']?['profilePicture']?.toString() ?? '',
      createdAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      jobId: json['jobId']?.toString(),
    );
  }
}
