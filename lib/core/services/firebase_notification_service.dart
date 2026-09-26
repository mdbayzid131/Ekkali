import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/constants/app_constants.dart';
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/core/services/notifications_service.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/firebase_options.dart';
import 'package:moeb_26/modules/bottom_nab_bar/controllers/bottom_nabbar_controller.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📬 Background Message: ${message.messageId}');
}

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize Firebase Messaging
  static Future<void> initialize() async {
    // Request permission (iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    } else {
      debugPrint('❌ User declined notification permission');
    }

    // On iOS, wait for APNS token before getting FCM token
    if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.ios) {
      debugPrint('🍎 Waiting for APNS Token...');
      String? apnsToken;
      int retryCount = 0;
      while (apnsToken == null && retryCount < 5) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 2));
          retryCount++;
          debugPrint('🍎 Retrying APNS Token ($retryCount/5)...');
        }
      }
      debugPrint('🍎 APNS Token: $apnsToken');
    }

    // Get FCM token
    try {
      String? token = await _messaging.getToken();
      debugPrint('🔑 FCM Token: $token');

      if (token != null) {
        AppConstants.fcmToken = token;
        await StorageService.setString(StorageConstants.fcmToken, token);
        await sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token Refreshed: $newToken');
      AppConstants.fcmToken = newToken;
      await StorageService.setString(StorageConstants.fcmToken, newToken);
      await sendTokenToBackend(newToken);
    });

    // Set foreground notification options (shows heads-up banner on iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Foreground Message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Listen to notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification Tapped: ${message.data}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App opened from notification: ${initialMessage.data}');
      pendingInitialMessage = initialMessage;
    }
  }

  static RemoteMessage? pendingInitialMessage;

  static void handleNotificationMessage(RemoteMessage message) {
    _handleNotificationTap(message);
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Local notification tapped: ${response.payload}');
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              jsonDecode(response.payload!),
            );
            _handleNotificationTap(RemoteMessage(data: data));
          } catch (e) {
            debugPrint('❌ Error handling local notification tap: $e');
          }
        }
      },
    );

    // Create notification channel with MAX importance for Heads-up Banner (Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Show local notification when app is in foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final Map<String, dynamic> data = message.data;
    final String type = (data['type'] ?? data['notificationType'] ?? '')
        .toString()
        .toUpperCase();
    final String? chatId = data['chatId']?.toString();

    // 1. If user is currently active inside this exact chat room, don't show the foreground banner popup
    if ((type == 'NEW_MESSAGE' || type == 'MESSAGE' || type == 'CHAT') &&
        chatId != null &&
        chatId.isNotEmpty) {
      if (Get.isRegistered<SocketService>()) {
        final activeChatId = Get.find<SocketService>().activeChatId;
        if (activeChatId != null && activeChatId == chatId) {
          debugPrint(
            '🔇 Suppressing foreground banner: user is actively chatting in $chatId',
          );
          return;
        }
      }
    }

    // 2. If community chat message and user is currently in community chat screen
    if (type == 'COMMUNITY_MESSAGE' || type == 'NEW_COMMUNITY_MESSAGE') {
      if (Get.isRegistered<SocketService>() &&
          Get.find<SocketService>().isCommunityActive) {
        debugPrint(
          '🔇 Suppressing foreground banner: user is actively in community chat',
        );
        return;
      }
    }

    // Extract title & body (supports both message.notification and data payload)
    final String title =
        message.notification?.title ??
        data['title']?.toString() ??
        'Notification';
    final String body =
        message.notification?.body ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        '';

    if (title.isEmpty && body.isEmpty) return;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.max,
          icon: 'ic_notification',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
          presentBadge: true,
          presentList: true,
        ),
      ),
      payload: jsonEncode({
        ...message.data,
        'title': title,
        'body': body,
      }),
    );
  }

  /// Unified navigation to the Ride page and Ride bottom sheet
  static void navigateToRideSheet(String? jobId) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    if (Get.currentRoute == Routes.bottomNabbarView) {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().navigateToRidesTab(targetJobId: jobId);
      } else {
        final nav = Get.put(NavigationController());
        nav.navigateToRidesTab(targetJobId: jobId);
      }
    } else {
      Get.offAllNamed(Routes.bottomNabbarView, arguments: {
        'bottomIndex': 1,
        'targetJobId': jobId,
      });
    }
  }

  /// Unified navigation to the Chat list tab (never chat detail screen)
  static void navigateToChatList() {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    if (Get.currentRoute == Routes.bottomNabbarView) {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().navigateToChatTab();
      } else {
        final nav = Get.put(NavigationController());
        nav.navigateToChatTab();
      }
    } else {
      Get.offAllNamed(Routes.bottomNabbarView, arguments: 2);
    }
  }

  /// Unified router for both push notification taps and in-app notification taps
  static void navigateToNotificationTarget({
    required String type,
    String? jobId,
    String? chatId,
    String? title,
    String? subtitle,
    Map<String, dynamic>? data,
  }) {
    Map<String, dynamic>? nestedData;
    if (data != null && data.containsKey('data')) {
      if (data['data'] is Map<String, dynamic>) {
        nestedData = data['data'] as Map<String, dynamic>;
      } else if (data['data'] is String) {
        try {
          final dec = jsonDecode(data['data']);
          if (dec is Map<String, dynamic>) {
            nestedData = dec;
          }
        } catch (_) {}
      }
    }

    final String resolvedJobId = (jobId != null && jobId.isNotEmpty)
        ? jobId
        : (data?['jobId']?.toString() ??
            nestedData?['jobId']?.toString() ??
            data?['id']?.toString() ??
            nestedData?['id']?.toString() ??
            data?['_id']?.toString() ??
            nestedData?['_id']?.toString() ??
            data?['rideId']?.toString() ??
            nestedData?['rideId']?.toString() ??
            (data != null && data['job'] is Map
                ? data['job']['_id']?.toString() ??
                    data['job']['id']?.toString()
                : null) ??
            (nestedData != null && nestedData['job'] is Map
                ? nestedData['job']['_id']?.toString() ??
                    nestedData['job']['id']?.toString()
                : null) ??
            (data != null && data['ride'] is Map
                ? data['ride']['_id']?.toString() ??
                    data['ride']['id']?.toString()
                : null) ??
            (nestedData != null && nestedData['ride'] is Map
                ? nestedData['ride']['_id']?.toString() ??
                    nestedData['ride']['id']?.toString()
                : null) ??
            '');

    final String resolvedChatId = (chatId != null && chatId.isNotEmpty)
        ? chatId
        : (data?['chatId']?.toString() ??
            nestedData?['chatId']?.toString() ??
            '');

    final String upperType = type.trim().toUpperCase();
    final String lowerTitle = (title ?? '').toLowerCase();
    final String lowerSubtitle = (subtitle ?? '').toLowerCase();

    debugPrint(
      '📍 Unified Notification Navigation: type=$upperType, jobId=$resolvedJobId, chatId=$resolvedChatId, title=$lowerTitle',
    );

    // 1. CHAT RELATED NOTIFICATIONS: Always go to Chat list (Index 2), NEVER chat detail
    final bool isChat = upperType == 'NEW_MESSAGE' ||
        upperType == 'MESSAGE' ||
        upperType == 'CHAT' ||
        upperType == 'COMMUNITY_MESSAGE' ||
        upperType == 'NEW_COMMUNITY_MESSAGE' ||
        resolvedChatId.isNotEmpty ||
        lowerTitle.contains('message') ||
        lowerTitle.contains('chat') ||
        lowerSubtitle.contains('message') ||
        lowerSubtitle.contains('chat');

    if (isChat) {
      navigateToChatList();
      return;
    }

    // 2. JOB RELATED NOTIFICATIONS: Always open Ride page & Bottom Sheet, NEVER separate job details
    final bool isJob = upperType == 'JOB_ASSIGNED' ||
        upperType == 'JOB_APPLICATION_RECEIVED' ||
        upperType == 'CHAUFFEUR_APPLIED' ||
        upperType == 'JOB_CANCELLED' ||
        upperType == 'JOB_REVIEWED' ||
        upperType == 'JOB_APPLICANT_REJECTED' ||
        upperType == 'TASK' ||
        upperType.contains('JOB') ||
        upperType.contains('RIDE') ||
        resolvedJobId.isNotEmpty ||
        lowerTitle.contains('job') ||
        lowerTitle.contains('ride') ||
        lowerTitle.contains('applicant') ||
        lowerTitle.contains('chauffeur') ||
        lowerTitle.contains('assigned') ||
        lowerTitle.contains('acceptance') ||
        lowerSubtitle.contains('job') ||
        lowerSubtitle.contains('ride');

    if (isJob) {
      if (upperType == 'JOB_APPLICANT_REJECTED' && resolvedJobId.isEmpty) {
        // Driver rejected without job info -> Available Jobs Feed
        Get.offAllNamed(Routes.bottomNabbarView, arguments: 0);
      } else {
        navigateToRideSheet(resolvedJobId.isNotEmpty ? resolvedJobId : null);
      }
      return;
    }

    // 3. SUPPORT TICKET
    if (upperType == 'SUPPORT' ||
        upperType == 'SUPPORT_MESSAGE' ||
        upperType == 'SUPPORT_TICKET' ||
        lowerTitle.contains('support') ||
        lowerSubtitle.contains('ticket')) {
      final String? ticketId = data?['ticketId']?.toString() ??
          data?['id']?.toString() ??
          data?['_id']?.toString();
      if (ticketId != null && ticketId.isNotEmpty) {
        Get.toNamed(
          Routes.supportTicketDetailView,
          arguments: {
            'ticketId': ticketId,
            'id': ticketId,
          },
        );
      } else {
        Get.toNamed(Routes.notificationsView);
      }
      return;
    }

    // 4. DEALS & OFFERS
    if (upperType == 'REMINDER' ||
        upperType == 'DEAL' ||
        upperType == 'OFFER' ||
        lowerTitle.contains('deal') ||
        lowerTitle.contains('offer') ||
        lowerTitle.contains('saving') ||
        lowerSubtitle.contains('deal') ||
        lowerSubtitle.contains('offer')) {
      Get.toNamed(Routes.dealsView);
      return;
    }

    // 5. INVOICES & PAYMENTS
    if (upperType.contains('INVOICE') ||
        upperType.contains('PAYMENT') ||
        lowerTitle.contains('invoice') ||
        lowerTitle.contains('payment') ||
        lowerSubtitle.contains('invoice') ||
        lowerSubtitle.contains('payment')) {
      Get.toNamed(Routes.invoiceHistoryView);
      return;
    }

    // 6. MARKETPLACE / ITEMS
    if (lowerTitle.contains('item') ||
        lowerTitle.contains('market') ||
        lowerSubtitle.contains('item') ||
        lowerSubtitle.contains('market')) {
      Get.toNamed(Routes.myItemsView);
      return;
    }

    // 7. DEFAULT FALLBACK
    if (Get.currentRoute == Routes.notificationsView) {
      Get.offAllNamed(Routes.bottomNabbarView, arguments: 0);
    } else {
      Get.toNamed(Routes.notificationsView);
    }
  }

  // Handle notification tap & Deep Linking
  static void _handleNotificationTap(RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    final String type = (data['type'] ?? data['notificationType'] ?? '')
        .toString();
    final String? jobId = data['jobId']?.toString() ?? data['id']?.toString();
    final String? chatId = data['chatId']?.toString();
    final String title = message.notification?.title ??
        data['title']?.toString() ??
        '';
    final String subtitle = message.notification?.body ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        '';

    navigateToNotificationTarget(
      type: type,
      jobId: jobId,
      chatId: chatId,
      title: title,
      subtitle: subtitle,
      data: data,
    );
  }

  // Send token to backend
  static Future<void> sendTokenToBackend(String? token) async {
    final String fcmToken = token ?? AppConstants.fcmToken;
    if (fcmToken.isEmpty) return;

    final String bearerToken = await StorageService.getString(
      StorageConstants.bearerToken,
    );
    if (bearerToken.isEmpty) return;

    try {
      final NotificationsService notifService =
          Get.isRegistered<NotificationsService>()
          ? Get.find<NotificationsService>()
          : Get.put(NotificationsService());

      await notifService.registerDeviceToken(fcmToken);
      debugPrint('✅ FCM Token successfully registered on backend: $fcmToken');
    } catch (e) {
      debugPrint('⚠️ Failed to register FCM token on backend: $e');
    }
  }

  // Remove token from backend on logout
  static Future<void> removeTokenFromBackend([String? token]) async {
    String fcmToken = token ?? AppConstants.fcmToken;
    if (fcmToken.isEmpty) {
      fcmToken = await StorageService.getString(StorageConstants.fcmToken);
    }
    if (fcmToken.isEmpty) return;

    try {
      final NotificationsService notifService =
          Get.isRegistered<NotificationsService>()
          ? Get.find<NotificationsService>()
          : Get.put(NotificationsService());

      await notifService.unregisterDeviceToken(fcmToken);
      debugPrint('✅ FCM Token successfully removed from backend: $fcmToken');
    } catch (e) {
      debugPrint('⚠️ Failed to remove FCM token from backend: $e');
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('❌ Unsubscribed from topic: $topic');
  }
}
