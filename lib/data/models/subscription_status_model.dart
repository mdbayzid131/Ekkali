class SubscriptionStatusResponse {
  final bool success;
  final String message;
  final SubscriptionStatusData? data;

  SubscriptionStatusResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? SubscriptionStatusData.fromJson(
              Map<String, dynamic>.from(json['data'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
    };
  }
}

class SubscriptionStatusData {
  final bool isPremium;
  final String? expiresAt;
  final String? platform;
  final String? productId;
  final String? orderId;

  SubscriptionStatusData({
    required this.isPremium,
    this.expiresAt,
    this.platform,
    this.productId,
    this.orderId,
  });

  factory SubscriptionStatusData.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusData(
      isPremium: json['isPremium'] as bool? ?? false,
      expiresAt: json['expiresAt'] as String?,
      platform: json['platform'] as String?,
      productId: json['productId'] as String?,
      orderId: json['orderId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPremium': isPremium,
      'expiresAt': expiresAt,
      'platform': platform,
      'productId': productId,
      'orderId': orderId,
    };
  }
}
