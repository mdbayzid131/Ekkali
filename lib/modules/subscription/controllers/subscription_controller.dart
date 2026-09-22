import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:moeb_26/core/services/subscription_service.dart';

class SubscriptionController extends GetxController {
  late final SubscriptionService _subscriptionService;

  // ─── Delegates from SubscriptionService ─────────────────────────────────────
  RxBool get isPremium => _subscriptionService.isPremium;
  RxBool get isLoading => _subscriptionService.isLoading;
  RxBool get isAvailable => _subscriptionService.isAvailable;
  Rx<ProductDetails?> get yearlyProduct => _subscriptionService.yearlyProduct;

  // Keep isSubscribed as alias for backward compat with any older UI references
  RxBool get isSubscribed => _subscriptionService.isPremium;

  // ─── Plan Display Info ────────────────────────────────────────────────────────
  final String planName = 'Ekkali Premium';
  final String planPeriod = '/ Year';

  bool get hasProduct => _subscriptionService.yearlyProduct.value != null;

  String get planPrice {
    final product = _subscriptionService.yearlyProduct.value;
    return product?.price ?? 'Not Found';
  }

  String get billingDescription {
    final product = _subscriptionService.yearlyProduct.value;
    if (product != null) {
      return 'Billed annually at ${product.price}';
    }
    return 'Product unavailable from store';
  }

  // ─── Feature List ─────────────────────────────────────────────────────────────
  final List<Map<String, String>> features = [
    {
      'title': 'Job Opportunities',
      'subtitle':
          'Access job opportunities posted by other chauffeurs and grow your business.',
      'icon': 'job',
    },
    {
      'title': 'Preferred Chauffeur Network',
      'subtitle':
          'Build your trusted network and connect with professional chauffeurs you can rely on.',
      'icon': 'network',
    },
    {
      'title': 'Live Service Area Chats',
      'subtitle':
          'Communicate in real time with chauffeurs in your service area or connect with other service areas.',
      'icon': 'chat',
    },
    {
      'title': 'Invoice Creator, Schedule & Expense Tracker',
      'subtitle':
          'Manage your private bookings, create professional invoices, organize your schedule, and track your business expenses.',
      'icon': 'invoice',
    },
    {
      'title': 'Meet & Greet Sign Creator',
      'subtitle':
          'Create professional airport and client welcome signs with ease.',
      'icon': 'flight',
    },
    {
      'title': 'Marketplace – Buy & Sell',
      'subtitle':
          'Buy and sell business-related items, equipment, or services within the Ekkali network.',
      'icon': 'marketplace',
    },
    {
      'title': 'Deals & Exclusive Offers',
      'subtitle':
          'Access exclusive deals, discounts, and special offers from businesses serving the chauffeur industry.',
      'icon': 'deals',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _subscriptionService = Get.find<SubscriptionService>();
    _subscriptionService.loadProducts();
    _subscriptionService.syncStatusWithBackend();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────────

  /// Triggers the real in-app purchase flow
  Future<void> subscribe() async {
    await _subscriptionService.buySubscription();
  }

  /// Restores previously purchased subscriptions
  Future<void> restorePurchases() async {
    await _subscriptionService.restorePurchases();
  }

  /// Legacy plan selector (kept for UI compatibility)
  void selectPlan(String planId) {}
}
