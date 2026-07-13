import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:billingapp/utils/app_logger.dart';

class ChatScreen extends StatefulWidget {
  final Map user;
  final String role;
  final int userId;

  const ChatScreen({
    super.key,
    required this.user,
    required this.role,
    required this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController msgController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final String baseUrl = "http://localhost:3002";

  List<Map<String, dynamic>> messages = [];
  bool loading = true;

  late int friendId;
  String myName = "";
  String friendName = "";

////////////////////////////////////////////////
  /// INIT
////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    init();
  }

  Future init() async {
    friendId = int.parse(widget.user["user_id"].toString());
    friendName = widget.user["name"] ?? "";

    await getMyName();

    fetchMessages();
  }

////////////////////////////////////////////////
  /// GET MY NAME
////////////////////////////////////////////////

  Future getMyName() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/cl_users"));
      final decoded = jsonDecode(res.body);

      List users = decoded["data"];

      final me = users.firstWhere(
            (u) => u["user_id"] == widget.userId,
        orElse: () => {},
      );

      myName = me["name"] ?? "";
    } catch (e) {
      AppLogger.error("getMyName error", e);
    }
  }

////////////////////////////////////////////////
  /// FETCH MESSAGES
////////////////////////////////////////////////

  Future fetchMessages() async {
    try {
      final url =
          "$baseUrl/messages/filter-by-role?userId=${widget.userId}&role=${widget.role}";

      final res = await http.get(Uri.parse(url));
      final decoded = jsonDecode(res.body);

      List list = [];

      if (decoded["data"] is Map &&
          decoded["data"]["data"] is List) {
        list = decoded["data"]["data"];
      }

      List<Map<String, dynamic>> chat = list
          .map((e) => Map<String, dynamic>.from(e))
          .where((m) {
        return (m["sender_id"] == widget.userId &&
            m["receiver_id"] == friendId) ||
            (m["sender_id"] == friendId &&
                m["receiver_id"] == widget.userId);
      }).toList();

      chat.sort((a, b) {
        DateTime t1 =
            DateTime.tryParse(a["created_at"] ?? "") ?? DateTime.now();
        DateTime t2 =
            DateTime.tryParse(b["created_at"] ?? "") ?? DateTime.now();
        return t1.compareTo(t2);
      });

      setState(() {
        messages = chat;
        loading = false;
      });

      scrollBottom();
    } catch (e) {
      AppLogger.error("fetchMessages error", e);
    }
  }

////////////////////////////////////////////////
  /// SEND MESSAGE (ONLY FIX HERE)
////////////////////////////////////////////////

  Future sendMessage() async {
    String msg = msgController.text.trim();
    if (msg.isEmpty) return;

    msgController.clear();

    setState(() {
      messages.add({
        "sender_id": widget.userId,
        "receiver_id": friendId,
        "message": msg,
        "created_at": DateTime.now().toIso8601String()
      });
    });

    scrollBottom();

    try {
      AppLogger.info("Sending message...");

      final res = await http.post(
        // ✅ FIX 1
        Uri.parse("$baseUrl/messages"),
        headers: {"Content-Type": "application/json"},

        // ✅ FIX 2
        body: jsonEncode({
          "conversation_id": 15, // ⚠️ your DB value
          "sender_id": widget.userId,
          "message": msg
        }),
      );

      AppLogger.api("POST", "$baseUrl/messages", res.statusCode);

      if (res.statusCode == 200) {
        AppLogger.success("Message sent");
      } else {
        AppLogger.api("POST", "$baseUrl/messages", res.statusCode, body: res.body, isError: true);
      }

    } catch (e) {
      AppLogger.error("sendMessage error", e);
    }
  }

////////////////////////////////////////////////
  /// SCROLL
////////////////////////////////////////////////

  void scrollBottom() {
    if (!scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 200), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

////////////////////////////////////////////////
  /// UI (UNCHANGED)
////////////////////////////////////////////////

  Widget bubble(Map m) {
    bool isMe = m["sender_id"] == widget.userId;

    DateTime time =
        DateTime.tryParse(m["created_at"] ?? "") ?? DateTime.now();

    String t = DateFormat('h:mm a').format(time);

    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 6,
          left: isMe ? 80 : 0,
          right: isMe ? 0 : 80,
        ),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[200] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(m["message"] ?? ""),
            const SizedBox(height: 3),
            Text(
              t,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            )
          ],
        ),
      ),
    );
  }

////////////////////////////////////////////////
  /// UI
////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff075E54),
        title: Text(friendName),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(child: Text("Start chatting"))
                : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (c, i) =>
                  bubble(messages[i]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgController,
                    decoration: InputDecoration(
                      hintText: "Type message",
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}