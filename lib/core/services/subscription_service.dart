import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/subscription_status_model.dart';
import 'package:moeb_26/data/repositories/subscription_repository.dart';

/// Product IDs – must match exactly what is set in App Store Connect & Google Play
class SubscriptionProductIds {
  static const String yearlyPremium = 'ekkali_premium_yearly';
  static const Set<String> all = {yearlyPremium};
}

class SubscriptionService extends GetxService {
  late final SubscriptionRepo _repo;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // ─── Testing / Debug Override ───────────────────────────────────────────────
  /// টেস্টিং পারপাসে পুরো অ্যাপে প্রিমিয়াম আনলক করতে চাইলে এটিকে `true` করে দিন।
  /// Normal production/live মোডের জন্য এটিকে `false` রাখুন।
  static const bool debugForcePremium = false;

  // ─── Observable State ───────────────────────────────────────────────────────
  final RxBool isPremium = (debugForcePremium ? true : false).obs;
  final RxBool isAvailable = false.obs;
  final RxBool isLoading = false.obs;
  final Rx<ProductDetails?> yearlyProduct = Rx<ProductDetails?>(null);
  final RxString subscriptionExpiry = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _repo = SubscriptionRepo(apiClient: Get.find<ApiClient>());
    _initService();
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }

  // ─── Initialization ──────────────────────────────────────────────────────────
  Future<void> _initService() async {
    if (debugForcePremium) {
      isPremium.value = true;
      debugPrint('[SubscriptionService] ⚡ DEBUG MODE: Forced Premium is ACTIVE');
      return;
    }

    // 1. Load cached premium status first so UI is instant (only if token exists)
    await _loadCachedStatus();

    // 2. Always sync status with backend if user has a token
    syncStatusWithBackend();

    // 3. Check if store is available
    isAvailable.value = await _iap.isAvailable();
    if (!isAvailable.value) {
      debugPrint('[SubscriptionService] Store not available.');
      return;
    }

    // 4. iOS: enable pending transactions
    if (Platform.isIOS) {
      final iosPlatformAddition = _iap
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    // 5. Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen(
      _onPurchaseUpdated,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (Object e) {
        debugPrint('[SubscriptionService] Purchase stream error: $e');
      },
    );

    // 6. Load products from store
    await loadProducts();
  }

  /// Load previously cached premium status from SharedPreferences (only if logged in)
  Future<void> _loadCachedStatus() async {
    final token = await StorageService.getString(StorageConstants.bearerToken);
    if (token.isEmpty) {
      isPremium.value = false;
      subscriptionExpiry.value = '';
      return;
    }

    final cached = (await StorageService.getBool(StorageConstants.isPremium)) ?? false;
    isPremium.value = cached;
    final expiry =
        await StorageService.getString(StorageConstants.subscriptionExpiry);
    if (expiry.isNotEmpty) {
      subscriptionExpiry.value = expiry;
      // Auto-expire if past expiry date
      try {
        final expiryDate = DateTime.parse(expiry);
        if (DateTime.now().isAfter(expiryDate)) {
          await _setNotPremium();
        }
      } catch (_) {}
    }
  }

  /// Fetch product details from the stores
  Future<void> loadProducts() async {
    try {
      if (!isAvailable.value) {
        isAvailable.value = await _iap.isAvailable();
      }
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        SubscriptionProductIds.all,
      );
      if (response.error != null) {
        debugPrint('[SubscriptionService] Product query error: ${response.error}');
        return;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          '[SubscriptionService] Warning: Product IDs not found in Store: ${response.notFoundIDs}. Make sure "ekkali_premium_yearly" is created & active in Play Console / App Store Connect.',
        );
      }
      if (response.productDetails.isNotEmpty) {
        ProductDetails? matched;
        for (final p in response.productDetails) {
          if (p.id == SubscriptionProductIds.yearlyPremium) {
            matched = p;
            break;
          }
        }
        yearlyProduct.value = matched ?? response.productDetails.first;
        debugPrint('[SubscriptionService] Product loaded: ${yearlyProduct.value?.title} (${yearlyProduct.value?.price})');
      }
    } catch (e) {
      debugPrint('[SubscriptionService] loadProducts error: $e');
    }
  }

  // ─── Purchase Flow ──────────────────────────────────────────────────────────

  /// Call this when user taps "Subscribe Now"
  Future<void> buySubscription() async {
    if (!isAvailable.value) {
      isAvailable.value = await _iap.isAvailable();
      if (!isAvailable.value) {
        Helpers.showCustomSnackBar(
          'Store is not available on this device.',
          isError: true,
        );
        return;
      }
    }

    if (yearlyProduct.value == null) {
      isLoading.value = true;
      await loadProducts();
      isLoading.value = false;
    }

    final product = yearlyProduct.value;
    if (product == null) {
      Helpers.showCustomSnackBar(
        'Product not found in Store (ID: ekkali_premium_yearly).',
        isError: true,
      );
      return;
    }

    isLoading.value = true;
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      // Result handled in _onPurchaseUpdated
    } catch (e) {
      isLoading.value = false;
      debugPrint('[SubscriptionService] buySubscription error: $e');
      Helpers.showCustomSnackBar(
        '$e',
        isError: true,
      );
    }
  }

  /// Call this when user taps "Restore Purchases"
  Future<void> restorePurchases() async {
    if (!isAvailable.value) return;
    isLoading.value = true;
    try {
      await _iap.restorePurchases();
      // Result handled in _onPurchaseUpdated
    } catch (e) {
      isLoading.value = false;
      debugPrint('[SubscriptionService] restorePurchases error: $e');
      Helpers.showCustomSnackBar(
        '$e',
        isError: true,
      );
    }
  }

  // ─── Purchase Stream Handler ─────────────────────────────────────────────────

  Future<void> _onPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails details in purchaseDetailsList) {
      debugPrint(
        '[SubscriptionService] Purchase update: ${details.productID} | ${details.status}',
      );

      if (details.status == PurchaseStatus.pending) {
        // No action needed – waiting for user to confirm (e.g., Ask to Buy)
        continue;
      }

      if (details.status == PurchaseStatus.error) {
        isLoading.value = false;
        final errMsg = details.error?.message ?? 'Purchase error';
        // Don't show error for user cancellation
        if (details.error?.code != 'storekit_duplicate_product_object') {
          Helpers.showCustomSnackBar(errMsg, isError: true);
        }
        if (details.pendingCompletePurchase) {
          try {
            await _iap.completePurchase(details);
          } catch (e) {
            debugPrint('[SubscriptionService] completePurchase error: $e');
          }
        }
        continue;
      }

      if (details.status == PurchaseStatus.canceled) {
        isLoading.value = false;
        if (details.pendingCompletePurchase) {
          try {
            await _iap.completePurchase(details);
          } catch (e) {
            debugPrint('[SubscriptionService] completePurchase error: $e');
          }
        }
        continue;
      }

      if (details.status == PurchaseStatus.purchased ||
          details.status == PurchaseStatus.restored) {
        // Verify with backend
        final verified = await _verifyWithBackend(details);
        if (verified) {
          await _setIsPremium(details);
          if (details.status == PurchaseStatus.purchased) {
            Helpers.showCustomSnackBar(
              'Welcome to Ekkali Premium! 🎉',
              isError: false,
            );
          } else {
            Helpers.showCustomSnackBar(
              'Purchase restored successfully!',
              isError: false,
            );
          }
        }
        // Note: If verification failed, _verifyWithBackend has already shown the specific error snackbar and set _setNotPremium()
        isLoading.value = false;
        if (details.pendingCompletePurchase) {
          try {
            await _iap.completePurchase(details);
          } catch (e) {
            debugPrint('[SubscriptionService] completePurchase error: $e');
          }
        }
      }
    }
  }

  // ─── Backend Verification ────────────────────────────────────────────────────

  /// Returns true only if purchase is successfully verified with backend
  Future<bool> _verifyWithBackend(PurchaseDetails details) async {
    try {
      if (Platform.isIOS) {
        // iOS: send receipt data to backend
        final receiptData = await SKReceiptManager.retrieveReceiptData();
        if (receiptData.isEmpty) {
          debugPrint('[SubscriptionService] No iOS receipt data available');
          Helpers.showCustomSnackBar('No Apple receipt found to restore.', isError: true);
          await _setNotPremium();
          return false;
        }
        final response =
            await _repo.verifyAppleReceipt(receiptData: receiptData);
        if (response.data != null && response.data is Map) {
          final res = SubscriptionStatusResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          );
          if (res.success && res.data != null && res.data!.isPremium) {
            final isPrem = res.data!.isPremium;
            final expiry = res.data!.expiresAt;
            await StorageService.setBool(StorageConstants.isPremium, isPrem);
            isPremium.value = isPrem;
            if (expiry != null && expiry.isNotEmpty) {
              await StorageService.setString(
                  StorageConstants.subscriptionExpiry, expiry);
              subscriptionExpiry.value = expiry;
            }
            return true;
          } else {
            final errorMsg = response.data?['message'] ??
                'Apple receipt verification failed.';
            Helpers.showCustomSnackBar(errorMsg.toString(), isError: true);
            await _setNotPremium();
            return false;
          }
        } else {
          final errorMsg = response.statusMessage ?? 'Verification failed.';
          Helpers.showCustomSnackBar(errorMsg.toString(), isError: true);
          await _setNotPremium();
          return false;
        }
      } else if (Platform.isAndroid) {
        // Android: send purchase token to backend
        final androidDetails = details.verificationData;
        final purchaseToken = androidDetails.serverVerificationData;
        final productId = details.productID;

        // Validation check: If user canceled or token/productId is empty, do NOT call backend
        if (purchaseToken.isEmpty || productId.isEmpty) {
          debugPrint(
              '[SubscriptionService] Empty purchaseToken or productId. Skipping backend verification.');
          Helpers.showCustomSnackBar('No Google Play purchase token found.', isError: true);
          await _setNotPremium();
          return false;
        }

        final response = await _repo.verifyGooglePurchase(
          purchaseToken: purchaseToken,
          productId: productId,
          orderId: details.purchaseID ?? '',
        );
        if (response.data != null && response.data is Map) {
          final res = SubscriptionStatusResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          );
          if (res.success && res.data != null && res.data!.isPremium) {
            final isPrem = res.data!.isPremium;
            final expiry = res.data!.expiresAt;
            await StorageService.setBool(StorageConstants.isPremium, isPrem);
            isPremium.value = isPrem;
            if (expiry != null && expiry.isNotEmpty) {
              await StorageService.setString(
                  StorageConstants.subscriptionExpiry, expiry);
              subscriptionExpiry.value = expiry;
            }
            return true;
          } else {
            final errorMsg = response.data?['message'] ??
                'Google Play purchase verification failed.';
            Helpers.showCustomSnackBar(errorMsg.toString(), isError: true);
            await _setNotPremium();
            return false;
          }
        } else {
          final errorMsg = response.statusMessage ?? 'Verification failed.';
          Helpers.showCustomSnackBar(errorMsg.toString(), isError: true);
          await _setNotPremium();
          return false;
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Backend verification error: $e');
      Helpers.showCustomSnackBar('Verification error: $e', isError: true);
      await _setNotPremium();
      return false;
    }
    await _setNotPremium();
    return false;
  }

  /// Sync subscription status from backend (non-blocking) - called on app start, login, or screen load
  Future<void> syncStatusWithBackend() async {
    if (debugForcePremium) {
      isPremium.value = true;
      return;
    }
    try {
      final token = await StorageService.getString(StorageConstants.bearerToken);
      if (token.isEmpty) {
        debugPrint('[SubscriptionService] No bearer token found. Skipping status sync.');
        isPremium.value = false;
        subscriptionExpiry.value = '';
        return;
      }

      final isApproved = await StorageService.getBool(StorageConstants.isApproved);
      final isOnboard = await StorageService.getBool(StorageConstants.isOnboard);
      if (isApproved != true || isOnboard != true) {
        debugPrint(
          '[SubscriptionService] User is pending approval or onboarding (isApproved: $isApproved, isOnboard: $isOnboard). Skipping subscription status sync.',
        );
        return;
      }

      final response = await _repo.getSubscriptionStatus();
      if (response.statusCode == 200 && response.data != null) {
        final statusModel = SubscriptionStatusResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        if (statusModel.success && statusModel.data != null) {
          final isPrem = statusModel.data!.isPremium;
          final expiry = statusModel.data!.expiresAt;

          await StorageService.setBool(StorageConstants.isPremium, isPrem);
          isPremium.value = isPrem;

          if (expiry != null && expiry.isNotEmpty) {
            await StorageService.setString(
                StorageConstants.subscriptionExpiry, expiry);
            subscriptionExpiry.value = expiry;
          } else if (!isPrem) {
            await StorageService.remove(StorageConstants.subscriptionExpiry);
            subscriptionExpiry.value = '';
          }
          debugPrint(
            '[SubscriptionService] Synced backend status: isPremium=$isPrem, expiresAt=$expiry',
          );
        }
      }
    } catch (e) {
      // Backend not available – keep cached status
      debugPrint('[SubscriptionService] Status sync error: $e');
    }
  }

  /// Clear subscription local data on logout
  Future<void> clearSubscriptionData() async {
    await StorageService.remove(StorageConstants.isPremium);
    await StorageService.remove(StorageConstants.subscriptionExpiry);
    isPremium.value = false;
    subscriptionExpiry.value = '';
    debugPrint('[SubscriptionService] Cleared subscription local data.');
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _setIsPremium(PurchaseDetails details) async {
    await StorageService.setBool(StorageConstants.isPremium, true);
    isPremium.value = true;
  }

  Future<void> _setNotPremium() async {
    await StorageService.setBool(StorageConstants.isPremium, false);
    await StorageService.remove(StorageConstants.subscriptionExpiry);
    isPremium.value = false;
    subscriptionExpiry.value = '';
  }
}

/// iOS StoreKit delegate – required for iOS 14+ to handle payment queue
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() => false;
}
