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
import 'package:moeb_26/data/models/chat_model.dart';
import 'package:moeb_26/firebase_options.dart';

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
      _handleNotificationTap(initialMessage);
    }
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
      payload: jsonEncode(message.data),
    );
  }

  // Handle notification tap & Deep Linking
  static void _handleNotificationTap(RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    final String type = (data['type'] ?? data['notificationType'] ?? '')
        .toString()
        .toUpperCase();
    final String? jobId = data['jobId']?.toString() ?? data['id']?.toString();
    final String? chatId = data['chatId']?.toString();

    debugPrint('📍 Navigating based on notification: type=$type, data=$data');

    switch (type) {
      case 'JOB_ASSIGNED':
        // Driver assigned to a ride -> My Rides / Ride Details
        if (jobId != null && jobId.isNotEmpty) {
          Get.toNamed(Routes.rideDetailsView, arguments: jobId);
        } else {
          Get.offAllNamed(Routes.bottomNabbarView, arguments: 1);
        }
        break;

      case 'JOB_REVIEWED':
        // Review received -> go to Jobs/Rides tab
        Get.offAllNamed(Routes.bottomNabbarView, arguments: 1);
        break;

      case 'CHAUFFEUR_APPLIED':
      case 'JOB_APPLICATION_RECEIVED':
        // Driver applied to creator's job -> Creator's Job Details / My Jobs
        if (jobId != null && jobId.isNotEmpty) {
          Get.toNamed(Routes.myJobProgressDetailsView, arguments: jobId);
        } else {
          Get.offAllNamed(Routes.bottomNabbarView, arguments: 1);
        }
        break;

      case 'JOB_APPLICANT_REJECTED':
        // Driver rejected -> Available Jobs Feed
        Get.offAllNamed(Routes.bottomNabbarView, arguments: 0);
        break;

      case 'JOB_CANCELLED':
        // Ride cancelled -> Alert / Job Details
        if (jobId != null && jobId.isNotEmpty) {
          Get.toNamed(Routes.myJobProgressDetailsView, arguments: jobId);
        } else {
          Get.offAllNamed(Routes.bottomNabbarView, arguments: 1);
        }
        break;

      case 'NEW_MESSAGE':
      case 'MESSAGE':
      case 'CHAT':
        // Chat message -> Chat Details screen or Chat tab
        if (chatId != null && chatId.isNotEmpty) {
          Get.toNamed(
            Routes.chatDetailView,
            arguments: ChatPreview(
              id: chatId,
              participants: const [],
              createdBy: '',
              createdAt: '',
              updatedAt: '',
            ),
          );
        } else {
          Get.offAllNamed(Routes.bottomNabbarView, arguments: 2);
        }
        break;

      case 'SUPPORT_MESSAGE':
      case 'SUPPORT_TICKET':
      case 'SUPPORT':
        final String? ticketId = data['ticketId']?.toString() ??
            data['id']?.toString() ??
            data['_id']?.toString();
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
        break;

      default:
        Get.toNamed(Routes.notificationsView);
        break;
    }
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
