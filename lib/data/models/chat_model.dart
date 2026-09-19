class ChatParticipant {
  final String id;
  final String name;
  final String? email;
  final String? profilePicture;

  ChatParticipant({
    required this.id,
    required this.name,
    this.email,
    this.profilePicture,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      profilePicture: json['profilePicture'],
    );
  }

  /// Get initials from the name (first letter of first two words)
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class ChatItem {
  final String id;
  final String title;
  final double price;
  final String? condition;
  final String? status;
  final String? location;
  final List<String> photos;

  ChatItem({
    required this.id,
    required this.title,
    required this.price,
    this.condition,
    this.status,
    this.location,
    this.photos = const [],
  });

  factory ChatItem.fromJson(Map<String, dynamic> json) {
    return ChatItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      condition: json['condition'],
      status: json['status'],
      location: json['location'],
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
    );
  }
}

class ChatPreview {
  final String id;
  final List<ChatParticipant> participants;
  final ChatItem? item;
  final String? jobId;
  String? lastMessage;
  String? lastMessageAt;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  int unreadCount;
  bool isRead;

  ChatPreview({
    required this.id,
    this.participants = const [],
    this.item,
    this.jobId,
    this.lastMessage,
    this.lastMessageAt,
    this.createdBy = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.unreadCount = 0,
    this.isRead = true,
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    final unread = json['unreadCount'] is int
        ? json['unreadCount'] as int
        : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0;
    final isReadVal = json['isRead'] is bool
        ? json['isRead'] as bool
        : (unread == 0);

    return ChatPreview(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      participants: json['participants'] != null
          ? (json['participants'] as List)
                .map((p) => ChatParticipant.fromJson(p))
                .toList()
          : [],
      item: json['itemId'] != null && json['itemId'] is Map
          ? ChatItem.fromJson(json['itemId'])
          : null,
      jobId: json['jobId'] is Map
          ? json['jobId']['id']?.toString() ?? json['jobId']['_id']?.toString()
          : json['jobId']?.toString(),
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'],
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      unreadCount: unread,
      isRead: isReadVal,
    );
  }

  /// Get the "other" participant (not the current user)
  ChatParticipant? getOtherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.id != currentUserId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }
}
