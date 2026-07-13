class ChatUser {
  final int id;
  final String name;
  final String? email;
  final String? role;

  ChatUser({required this.id, required this.name, this.email, this.role});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: int.parse(json['user_id']?.toString() ?? json['id']?.toString() ?? '0'),
      name: json['name'] ?? 'User',
      email: json['email'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };
}

class Conversation {
  final int id;
  final ChatUser otherUser;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, int currentUserId) {
    ChatUser otherUser;
    
    // Support both backend format (user1/user2) and cached format (other_user)
    if (json['other_user'] != null) {
      otherUser = ChatUser.fromJson(json['other_user']);
    } else {
      var user1 = ChatUser.fromJson(json['user1'] ?? {});
      var user2 = ChatUser.fromJson(json['user2'] ?? {});
      otherUser = (user1.id == currentUserId) ? user2 : user1;
    }

    return Conversation(
      id: int.parse(json['id']?.toString() ?? '0'),
      otherUser: otherUser,
      lastMessage: json['last_message'],
      lastMessageTime: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'other_user': otherUser.toJson(),
    'last_message': lastMessage,
    'updated_at': lastMessageTime?.toIso8601String(),
    'unread_count': unreadCount,
  };
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String message;
  final String? imagePath;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    this.imagePath,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: int.parse(json['id']?.toString() ?? '0'),
      conversationId: int.parse(json['conversation_id']?.toString() ?? '0'),
      senderId: int.parse(json['sender_id']?.toString() ?? '0'),
      message: json['message'] ?? '',
      imagePath: json['image_path'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }
}
