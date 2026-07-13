import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:billingapp/utils/app_logger.dart';

/// Data Model
class Message {
  final int id;
  final int senderId;
  final int conversationId;
  final String content;
  final String createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.conversationId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: int.tryParse(json['id'].toString()) ?? 0,
      senderId:
      int.tryParse((json['sender_id'] ?? json['senderId'] ?? '0').toString()) ??
          0,
      conversationId:
      int.tryParse((json['conversation_id'] ?? '0').toString()) ?? 0,
      content: json['content'] ?? json['message'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ViewScreen extends StatefulWidget {
  final int currentUserId;
  final int friendId;
  final String friendName;

  const ViewScreen({
    Key? key,
    required this.currentUserId,
    required this.friendId,
    required this.friendName,
  }) : super(key: key);

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {

  List<Message> _messages = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _conversationId = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initChat();

    /// AUTO REFRESH
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_conversationId != 0) {
        _fetchMessages(isAuto: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initChat() async {
    await _getConversation();
    if (_conversationId != 0) {
      await _fetchMessages();
    }
  }

  /// GET CONVERSATION
  Future<void> _getConversation() async {
    try {

      final url = Uri.parse("http://localhost:3002/conversations");
      final response = await http.get(url);

      if (response.statusCode == 200) {

        final decoded = json.decode(response.body);

        List list = [];

        if (decoded["data"] is Map) {
          list = decoded["data"]["data"] ?? [];
        } else if (decoded["data"] is List) {
          list = decoded["data"];
        }

        for (var item in list) {

          int u1 = int.tryParse(item["user_one"].toString()) ?? 0;
          int u2 = int.tryParse(item["user_two"].toString()) ?? 0;

          if ((u1 == widget.currentUserId && u2 == widget.friendId) ||
              (u1 == widget.friendId && u2 == widget.currentUserId)) {

            _conversationId =
                int.tryParse(item["id"].toString()) ?? 0;

            break;
          }
        }
      }

    } catch (e) {
      AppLogger.error("Conversation error", e);
    }
  }

  /// FETCH MESSAGES
  Future<void> _fetchMessages({bool isAuto = false}) async {

    try {

      if (!isAuto) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      final url = Uri.parse(
          "http://jobes24x7.com/messages/filter-by-role?userId=${widget.currentUserId}&role=user");

      final response = await http.get(url);

      if (response.statusCode == 200) {

        final decoded = json.decode(response.body);

        List list = [];

        if (decoded["data"] is Map) {
          list = decoded["data"]["data"] ?? [];
        } else if (decoded["data"] is List) {
          list = decoded["data"];
        }

        List<Message> allMessages =
        list.map((e) => Message.fromJson(e)).toList();

        /// FILTER BY CONVERSATION
        List<Message> friendMessages = allMessages.where((msg) {
          return msg.conversationId == _conversationId;
        }).toList();

        /// SORT BY TIME
        friendMessages.sort((a, b) {
          DateTime t1 = DateTime.tryParse(a.createdAt) ?? DateTime.now();
          DateTime t2 = DateTime.tryParse(b.createdAt) ?? DateTime.now();
          return t1.compareTo(t2);
        });

        if (mounted) {
          setState(() {
            _messages = friendMessages;
            _isLoading = false;
          });
        }

      } else {

        if (!isAuto) {
          setState(() {
            _errorMessage = "API Error ${response.statusCode}";
            _isLoading = false;
          });
        }

      }

    } catch (e) {

      if (!isAuto) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }

    }
  }

  /// UI
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.friendName),
        backgroundColor: const Color(0xFF075E54),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchMessages(),
          ),
        ],
      ),

      backgroundColor: const Color(0xFFECE5DD),

      body: _buildBody(),

    );
  }

  Widget _buildBody() {

    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _messages.isEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(child: Text("No messages yet"));
    }

    return ListView.builder(

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),

      itemCount: _messages.length,

      itemBuilder: (context, index) {

        final message = _messages[index];

        final isMe = message.senderId == widget.currentUserId;

        return _bubble(message.content, isMe);

      },
    );
  }

  Widget _bubble(String text, bool isMe) {

    return Align(

      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(

        margin: const EdgeInsets.only(bottom: 8, top: 4),

        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        decoration: BoxDecoration(

          color: isMe
              ? const Color(0xFFDCF8C6)
              : Colors.white,

          borderRadius: BorderRadius.only(

            topLeft: const Radius.circular(12),

            topRight: const Radius.circular(12),

            bottomLeft: Radius.circular(isMe ? 12 : 0),

            bottomRight: Radius.circular(isMe ? 0 : 12),

          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],

        ),

        child: Text(
          text,
          style: const TextStyle(
              fontSize: 16,
              color: Colors.black87),
        ),

      ),
    );
  }
}