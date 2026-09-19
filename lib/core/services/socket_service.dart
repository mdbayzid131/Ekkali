import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/data/models/chat_message_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:moeb_26/core/services/storege_service.dart';
import 'api_client.dart';

class SocketService extends GetxService with WidgetsBindingObserver {
  late IO.Socket socket;
  final isConnected = false.obs;
  bool isSocketInitialized = false;
  String? _currentRoomId;

  // Stream for global message updates
  final Rxn<ChatMessage> lastReceivedMessage = Rxn<ChatMessage>();
  // Stream for community message updates
  final Rxn<dynamic> lastReceivedCommunityMessage = Rxn<dynamic>();

  // Streams for real-time job & ride events
  final Rxn<dynamic> lastCreatedJob = Rxn<dynamic>();
  final Rxn<dynamic> lastRemovedJobFeed = Rxn<dynamic>();
  final Rxn<dynamic> lastJobApplication = Rxn<dynamic>();
  final Rxn<dynamic> lastJobAssigned = Rxn<dynamic>();
  final Rxn<dynamic> lastRideStatusUpdated = Rxn<dynamic>();
  final Rxn<dynamic> lastJobCancelled = Rxn<dynamic>();

  // Currently active screen tracking
  String? activeChatId;
  String? currentCommunityArea;
  bool isCommunityActive = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    initSocket();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 SocketService: App resumed, checking connection...');
      if (isSocketInitialized && !socket.connected) {
        socket.connect();
      }
    }
  }

  Future<void> initSocket() async {
    // If socket already exists and is connected, don't re-init
    if (isSocketInitialized && socket.connected) {
      debugPrint('ℹ️ SocketService: Socket already connected, skipping init');
      return;
    }

    // If exists but not connected, dispose and re-create
    if (isSocketInitialized) {
      socket.dispose();
      isSocketInitialized = false;
    }

    String token = await StorageService.getString(StorageConstants.bearerToken);

    // Check temporary token if bearer token is missing (Restricted mode support)
    if (token.isEmpty && Get.isRegistered<ApiClient>()) {
      token = ApiClient.temporaryToken ?? "";
    }

    if (token.isEmpty) {
      debugPrint('⚠️ SocketService: No token found, skipping connection');
      return;
    }

    // Extract socket URL from ApiConstants.baseUrl
    String baseUrl = ApiConstants.baseUrl;
    String socketUrl = baseUrl.replaceAll('/api/v1', '');

    debugPrint('🌐 SocketService: Initializing socket on: $socketUrl');

    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'randomizationFactor': 0.5,
      'timeout': 20000,
      'extraHeaders': {'Authorization': 'Bearer $token'},
      'query': {'token': token},
      // socket.io v3/v4 auth object
      'auth': {'token': token},
    });

    isSocketInitialized = true;

    socket.onConnect((_) {
      isConnected.value = true;
      debugPrint('✅ SocketService: Connected to server');
      debugPrint(
        '🔗 SocketService: Transport: ${socket.io.engine?.transport?.name}',
      );

      if (_currentRoomId != null) {
        socket.emit('join-room', _currentRoomId);
      }
      if (currentCommunityArea != null && currentCommunityArea!.isNotEmpty) {
        joinRoom('community::$currentCommunityArea');
      }
    });

    socket.onDisconnect((reason) {
      isConnected.value = false;
      debugPrint('❌ SocketService: Disconnected from server. Reason: $reason');
    });

    socket.onConnectError((err) {
      debugPrint('⚠️ SocketService: Connect Error: $err');
    });

    socket.on('connect_timeout', (data) {
      debugPrint('⏰ SocketService: Connect Timeout: $data');
    });

    socket.onError((err) {
      debugPrint('🚨 SocketService: Error: $err');
    });

    // 1. All message events listener
    final List<String> messageEvents = [
      'NEW_MESSAGE',
      'new_message',
      'message',
      'receive-message',
    ];
    for (var event in messageEvents) {
      socket.on(event, (data) => _handleIncomingMessage(data, event));
    }

    // 2. Community message events
    final List<String> commEvents = [
      'COMMUNITY_NEW_MESSAGE',
      'community_new_message',
      'community_message',
      'new_community_message',
      'COMMUNITY_MESSAGE',
      'NEW_COMMUNITY_MESSAGE',
      'newCommunityMessage',
      'communityMessage',
      'COMMUNITY_CHAT_MESSAGE',
      'community_chat_message',
    ];
    for (var event in commEvents) {
      socket.on(event, (data) {
        debugPrint('📥 SocketService: Received community event [$event]: $data');
        lastReceivedCommunityMessage.value = data;
      });
    }

    // 3. Driver Feed: JOB_CREATED
    final List<String> jobCreatedEvents = [
      'JOB_CREATED',
      'job_created',
      'jobCreated',
    ];
    for (var event in jobCreatedEvents) {
      socket.on(event, (data) {
        debugPrint('📥 SocketService: Received event [$event]: $data');
        lastCreatedJob.value = data;
      });
    }

    // 4. Driver Feed: JOB_REMOVED_FROM_FEED
    final List<String> jobRemovedEvents = [
      'JOB_REMOVED_FROM_FEED',
      'job_removed_from_feed',
      'jobRemovedFromFeed',
      'JOB_REMOVED',
    ];
    for (var event in jobRemovedEvents) {
      socket.on(event, (data) {
        debugPrint('📥 SocketService: Received event [$event]: $data');
        lastRemovedJobFeed.value = data;
      });
    }

    // 5. Creator My Jobs: JOB_APPLICATION_RECEIVED
    final List<String> jobAppEvents = [
      'JOB_APPLICATION_RECEIVED',
      'job_application_received',
      'jobApplicationReceived',
    ];
    for (var event in jobAppEvents) {
      socket.on(event, (data) {
        debugPrint('📥 SocketService: Received event [$event]: $data');
        lastJobApplication.value = data;
      });
    }

    // 6. Driver My Rides: JOB_ASSIGNED
    final List<String> jobAssignedEvents = [
      'JOB_ASSIGNED',
      'job_assigned',
      'jobAssigned',
    ];
    for (var event in jobAssignedEvents) {
      socket.on(event, (data) {
        debugPrint('📥 SocketService: Received event [$event]: $data');
        lastJobAssigned.value = data;
      });
    }

    // 7. Live Ride Tracking: RIDE_STATUS_UPDATED
    final List<String> rideStatusEvents = [
      'RIDE_STATUS_UPDATED',
      'ride_status_updated',
      'rideStatusUpdated',
    ];
    for (var event in rideStatusEvents) {
      socket.on(event, (data) {
        debugPrint('📥 SocketService: Received event [$event]: $data');
        lastRideStatusUpdated.value = data;
      });
    }

    // 8. Job / Ride Cancelled: JOB_CANCELLED
    final List<String> jobCancelledEvents = [
      'JOB_CANCELLED',
      'job_cancelled',
      'jobCancelled',
    ];
    for (var event in jobCancelledEvents) {
      socket.on(event, (data) {
        debugPrint('📥 SocketService: Received event [$event]: $data');
        lastJobCancelled.value = data;
      });
    }

    // Reconnection events for debugging
    socket.onReconnect((_) => debugPrint('🔄 SocketService: Reconnected'));
    socket.onReconnectAttempt(
      (count) => debugPrint('🔄 SocketService: Reconnect attempt #$count'),
    );

    socket.connect();
  }

  final Set<String> _activeRooms = {};

  void _handleIncomingMessage(dynamic data, String eventName) {
    debugPrint('📥 SocketService: Received event [$eventName]');
    debugPrint('📦 SocketService: Raw data: $data');

    if (data != null) {
      try {
        dynamic actualData = data;

        if (data is Map) {
          if (data.containsKey('data')) {
            actualData = data['data'];
          } else if (data.containsKey('message') && data['message'] is Map) {
            actualData = data['message'];
          }
        }

        // Check if this is a community message sent via generic message event
        if (actualData is Map &&
            (actualData.containsKey('serviceArea') ||
                (actualData['chatId'] == null ||
                    actualData['chatId'].toString().isEmpty))) {
          lastReceivedCommunityMessage.value = actualData;
        }

        final newMessage = ChatMessage.fromJson(actualData);
        lastReceivedMessage.value = newMessage;
        debugPrint(
          '✅ SocketService: Message parsed successfully and broadcasted',
        );
      } catch (e) {
        debugPrint(
          '❌ SocketService: Error parsing message from event [$eventName]: $e',
        );
      }
    }
  }

  void joinRoom(String roomId) {
    _activeRooms.add(roomId);
    _currentRoomId = roomId;
    if (!isSocketInitialized) {
      debugPrint(
        '⚠️ SocketService: joinRoom called but socket not initialized. Init now...',
      );
      initSocket();
      return;
    }

    if (socket.connected) {
      socket.emit('join-room', roomId);
      socket.emit('join', roomId);
      socket.emit('join_room', roomId);
      debugPrint('➡️ SocketService: Emitted join-room for roomId: $roomId');
    } else {
      debugPrint(
        '⚠️ SocketService: Cannot join room, socket not connected. Reconnecting... RoomId: $roomId',
      );
      socket.connect();
    }
  }

  void leaveRoom(String roomId) {
    _activeRooms.remove(roomId);
    _currentRoomId = null;
    if (isSocketInitialized && socket.connected) {
      socket.emit('leave-room', roomId);
      socket.emit('leave', roomId);
      debugPrint('⬅️ SocketService: Emitted leave-room for roomId: $roomId');
    }
  }

  /// Join a community / live chat room (emits JOIN_COMMUNITY and join-room)
  void joinCommunity(String serviceArea) {
    if (serviceArea.isEmpty) return;
    if (currentCommunityArea != null &&
        currentCommunityArea!.isNotEmpty &&
        currentCommunityArea != serviceArea) {
      leaveRoom('community::$currentCommunityArea');
    }
    currentCommunityArea = serviceArea;
    debugPrint('➡️ SocketService: Joining community room: community::$serviceArea');
    emit('JOIN_COMMUNITY', {'serviceArea': serviceArea});
    joinRoom('community::$serviceArea');
  }

  /// Leave a community room
  void leaveCommunity(String serviceArea) {
    if (serviceArea.isEmpty) return;
    debugPrint('⬅️ SocketService: Leaving community room: community::$serviceArea');
    emit('LEAVE_COMMUNITY', {'serviceArea': serviceArea});
    leaveRoom('community::$serviceArea');
    if (currentCommunityArea == serviceArea) {
      currentCommunityArea = null;
    }
  }

  /// Join a job room for live tracking (emits JOIN_JOB and join-room)
  void joinJob(String jobId) {
    if (jobId.isEmpty) return;
    debugPrint('➡️ SocketService: Joining job: $jobId');
    emit('JOIN_JOB', {'jobId': jobId});
    joinRoom('job::$jobId');
  }

  /// Leave a job room (emits LEAVE_JOB and leave-room)
  void leaveJob(String jobId) {
    if (jobId.isEmpty) return;
    debugPrint('⬅️ SocketService: Leaving job: $jobId');
    emit('LEAVE_JOB', {'jobId': jobId});
    leaveRoom('job::$jobId');
  }

  /// Join a chat room (emits JOIN_CHAT and join-room)
  void joinChat(String chatId) {
    if (chatId.isEmpty) return;
    activeChatId = chatId;
    debugPrint('➡️ SocketService: Joining chat: $chatId');
    emit('JOIN_CHAT', {'chatId': chatId});
    joinRoom('chat::$chatId');
  }

  /// Leave a chat room (emits LEAVE_CHAT and leave-room)
  void leaveChat(String chatId) {
    if (chatId.isEmpty) return;
    if (activeChatId == chatId) {
      activeChatId = null;
    }
    debugPrint('⬅️ SocketService: Leaving chat: $chatId');
    emit('LEAVE_CHAT', {'chatId': chatId});
    leaveRoom('chat::$chatId');
  }

  void on(String event, Function(dynamic) handler) {
    if (isSocketInitialized) {
      socket.on(event, handler);
    }
  }

  void off(String event) {
    if (isSocketInitialized) {
      socket.off(event);
    }
  }

  void emit(String event, dynamic data) {
    if (isSocketInitialized) {
      socket.emit(event, data);
    }
  }

  @override
  void onClose() {
    if (isSocketInitialized) {
      socket.dispose();
    }
    super.onClose();
  }
}
