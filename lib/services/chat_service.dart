import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:billingapp/utils/app_logger.dart';
import '../models/chat_models.dart';

class ChatService {
  // Use the correct base URL for your chat server
  static const String baseUrl = "http://192.168.0.110:3002"; 

  /// ✅ 1. Get or Create Conversation (Returns existing if found)
  static Future<int> getOrCreateConversation(int user1Id, int user2Id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/conversation/get-or-create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user1_id": user1Id,
          "user2_id": user2Id,
        }),
      );

      AppLogger.api("POST", "$baseUrl/conversation/get-or-create", response.statusCode);

      final decoded = jsonDecode(response.body);
      
      // We expect the ID to be in decoded['data']['id'] or decoded['id']
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = decoded['data'];
        if (data != null) {
          return int.parse(data['id'].toString());
        }
        return int.parse(decoded['id'].toString());
      }
      throw Exception("Failed to handle conversation API");
    } catch (e) {
      AppLogger.error("getOrCreateConversation error", e);
      rethrow;
    }
  }

  /// ✅ 2. Fetch Conversations for List
  static Future<List<Conversation>> fetchConversations(int currentUserId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/conversations"));
      AppLogger.api("GET", "$baseUrl/conversations", response.statusCode);
      
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        List data = decoded['data'] ?? [];
        return data.map((json) => Conversation.fromJson(json, currentUserId)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.error("fetchConversations error", e);
      return [];
    }
  }

  /// ✅ 3. Fetch Messages for a Conversation
  static Future<List<ChatMessage>> fetchMessages(int conversationId) async {
    try {
      final url = "$baseUrl/messages?conversation_id=$conversationId";
      final response = await http.get(Uri.parse(url));

      AppLogger.api("GET", url, response.statusCode);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // Handle different possible response structures
        dynamic list;
        if (decoded['data'] is Map) {
          list = decoded['data']['data'] ?? decoded['data']['messages'];
        } else if (decoded['data'] is List) {
          list = decoded['data'];
        } else {
          list = decoded; // Assume the whole body is the list
        }

        if (list is List) {
          return list.map((m) => ChatMessage.fromJson(m)).toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.error("fetchMessages error", e);
      return [];
    }
  }

  /// ✅ 4. Send a New Message
  static Future<ChatMessage?> sendMessage(int conversationId, int senderId, String text) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/message/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "conversation_id": conversationId,
          "sender_id": senderId,
          "message": text,
          "image_path": null
        }),
      );

      AppLogger.api("POST", "$baseUrl/message/create", response.statusCode);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = decoded['data'] ?? decoded;
        return ChatMessage.fromJson(data);
      }
      return null;
    } catch (e) {
      AppLogger.error("sendMessage error", e);
      return null;
    }
  }

  /// ✅ 5. Mark Messages as Seen
  static Future<bool> markSeen(int conversationId, int userId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/messages/mark-seen"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "conversation_id": conversationId,
          "user_id": userId,
        }),
      );

      AppLogger.api("PUT", "$baseUrl/messages/mark-seen", response.statusCode);
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error("markSeen error", e);
      return false;
    }
  }
}
