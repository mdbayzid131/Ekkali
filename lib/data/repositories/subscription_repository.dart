import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class SubscriptionRepo {
  final ApiClient _apiClient;

  SubscriptionRepo({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Verify Apple (iOS) receipt with backend
  Future<Response> verifyAppleReceipt({
    required String receiptData,
  }) async {
    return await _apiClient.postData(
      ApiConstants.subscriptionVerifyApple,
      {'receipt': receiptData},
    );
  }

  /// Verify Google Play purchase token with backend
  Future<Response> verifyGooglePurchase({
    required String purchaseToken,
    required String productId,
    required String orderId,
  }) async {
    return await _apiClient.postData(
      ApiConstants.subscriptionVerifyGoogle,
      {
        'purchaseToken': purchaseToken,
        'productId': productId,
        'orderId': orderId,
      },
    );
  }

  /// Restore purchases – backend re-validates and returns status
  Future<Response> restorePurchases() async {
    return await _apiClient.postData(
      ApiConstants.subscriptionRestore,
      {},
    );
  }

  /// Get current subscription status from backend
  Future<Response> getSubscriptionStatus() async {
    return await _apiClient.getData(ApiConstants.subscriptionStatus);
  }
}
