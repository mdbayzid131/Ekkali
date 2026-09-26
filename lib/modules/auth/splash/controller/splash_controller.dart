import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:moeb_26/firebase_options.dart';
import 'package:moeb_26/core/services/firebase_notification_service.dart';
import 'package:moeb_26/config/constants/app_constants.dart';
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/subscription_service.dart';
import 'package:moeb_26/core/services/auth_service.dart';
import 'package:moeb_26/modules/auth/authentication/views/auth_selection_view.dart';
import 'package:moeb_26/core/services/storege_service.dart';

class SplashScreenController extends GetxController {
  RxInt currentIndex = 0.obs; // Reactive state for dot index
  Timer? _periodicTimer;
  Timer? _navigationTimer;

  @override
  void onInit() {
    super.onInit();
    _initAsync();
    startTimer();
  }

  @override
  void onReady() {
    super.onReady();
    _initFirebaseAndFCM();
  }

  Future<void> _initFirebaseAndFCM() async {
    try {
      // Initialize Firebase asynchronously after the first frame has rendered
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      // Initialize FCM token and permissions
      await FirebaseNotificationService.initialize();
    } catch (e) {
      Get.log('❌ Firebase/FCM Initialization error: $e');
    }
  }

  Future<void> _initAsync() async {
    AppConstants.fcmToken = await StorageService.getString(
      StorageConstants.fcmToken,
    );
  }

  // Start the timer and change the dot index over time
  void startTimer() {
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentIndex.value < 2) {
        currentIndex.value++; // Update the current dot index
      } else {
        timer.cancel();
      }
    });

    // After 3 seconds, check login and navigate
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      checkLogin();
    });
  }

  Future<void> checkLogin() async {
    final accessToken = await StorageService.getString(
      StorageConstants.bearerToken,
    );
    final bool? isApproved = await StorageService.getBool(
      StorageConstants.isApproved,
    );

    // Only auto-login directly to home if the user is already approved
    if (accessToken.isNotEmpty && isApproved == true) {
      try {
        if (Get.isRegistered<SubscriptionService>()) {
          Get.find<SubscriptionService>().syncStatusWithBackend();
        }
      } catch (_) {}

      // If user opened the app from a push notification in terminated state, route appropriately
      if (FirebaseNotificationService.pendingInitialMessage != null) {
        final initialMsg = FirebaseNotificationService.pendingInitialMessage!;
        FirebaseNotificationService.pendingInitialMessage = null;
        FirebaseNotificationService.handleNotificationMessage(initialMsg);
      } else {
        Get.offAllNamed(Routes.bottomNabbarView);
      }
    } else {
      // Incomplete onboarding, unapproved, or logged out:
      // Clear incomplete local session so user logs in and gets fresh server status
      try {
        if (Get.isRegistered<AuthService>()) {
          await Get.find<AuthService>().clearLocalAuth();
        }
        if (Get.isRegistered<SubscriptionService>()) {
          Get.find<SubscriptionService>().clearSubscriptionData();
        }
      } catch (_) {}

      Get.offAll(() => const AuthSelectionView());
    }
  }

  @override
  void onClose() {
    _periodicTimer?.cancel();
    _navigationTimer?.cancel();
    super.onClose();
  }
}
