import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'chat_constants.dart';
import '../services/chat_service.dart';

// --- Models ---

enum MessageStatus { sent, delivered, read }

class SupportContact {
  final int id;
  final String shopName;
  final String phone;
  final String address;
  final String dept;
  final String category;

  SupportContact({
    required this.id,
    required this.shopName, 
    required this.phone, 
    required this.address,
    required this.dept,
    this.category = "Business",
  });
}

class LocalMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  MessageStatus status;

  LocalMessage({
    required this.text, 
    required this.isMe, 
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isMe': isMe,
    'timestamp': timestamp.toIso8601String(),
    'status': status.index,
  };

  factory LocalMessage.fromJson(Map<String, dynamic> json) => LocalMessage(
    text: json['text'],
    isMe: json['isMe'],
    timestamp: DateTime.parse(json['timestamp']),
    status: MessageStatus.values[json['status'] ?? 0],
  );
}

class ChatSuggestion {
  final String text;
  final IconData icon;
  final List<String> keywords;

  ChatSuggestion({required this.text, required this.icon, required this.keywords});
}

// --- Main Support List Screen ---

class SupportChatScreen extends StatefulWidget {
  final int? currentUserId;
  final int? targetUserId;
  final String? targetUserName;
  final int? conversationId;

  const SupportChatScreen({
    super.key,
    this.currentUserId,
    this.targetUserId,
    this.targetUserName,
    this.conversationId,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _unreadCounts = {};
  Map<String, String> _lastMessages = {};

  final List<SupportContact> _allContacts = ChatConstants.allContacts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUnreadCounts();
    _loadLastMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('support_unread_counts');
    if (data != null) {
      setState(() {
        _unreadCounts = Map<String, int>.from(jsonDecode(data));
      });
    }
  }

  Future<void> _loadLastMessages() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, String> lasts = {};
    for (var contact in _allContacts) {
      final String? chatData = prefs.getString('local_chat_${contact.phone}');
      if (chatData != null) {
        final List<dynamic> messages = jsonDecode(chatData);
        if (messages.isNotEmpty) {
          lasts[contact.phone] = messages.last['text'] ?? "";
        }
      }
    }
    setState(() {
      _lastMessages = lasts;
    });
  }

  List<SupportContact> get _businessContacts => 
      _allContacts.where((c) => c.category == "Business").toList();

  List<SupportContact> get _adminContacts => 
      _allContacts.where((c) => c.category == "Admin").toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Support Chat", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: const Color(0xFF2563EB),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: "Business (${_businessContacts.length})"),
                  Tab(text: "Admin (${_adminContacts.length})"),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactList(_businessContacts),
          _buildContactList(_adminContacts),
        ],
      ),
    );
  }

  Widget _buildContactList(List<SupportContact> contacts) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: contacts.length,
      separatorBuilder: (context, index) => const Divider(indent: 80, height: 1, color: Color(0xFFF3F4F6)),
      itemBuilder: (context, index) {
        return _buildContactCard(contacts[index]);
      },
    );
  }

  Widget _buildContactCard(SupportContact contact) {
    int unread = _unreadCounts[contact.phone] ?? 0;
    String lastMsg = _lastMessages[contact.phone] ?? "Start a conversation";
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SupportChatDetailScreen(
              contact: contact,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
        _loadUnreadCounts();
        _loadLastMessages();
      },
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              contact.shopName[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 18),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              contact.shopName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text(
            "10:45 AM", // Static for demo, could be real time
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unread > 0 ? Colors.black87 : Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (unread > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unread.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Advanced Chat Detail Screen with Smart Suggestions ---

class SupportChatDetailScreen extends StatefulWidget {
  final SupportContact contact;
  final int? currentUserId;
  final int? conversationId;

  const SupportChatDetailScreen({
    super.key, 
    required this.contact,
    this.currentUserId,
    this.conversationId,
  });

  @override
  State<SupportChatDetailScreen> createState() => _SupportChatDetailScreenState();
}

class _SupportChatDetailScreenState extends State<SupportChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<LocalMessage> _messages = [];
  bool _isLoading = true;
  String _lastSeen = "Online";

  // Suggestion System
  List<ChatSuggestion> _visibleSuggestions = [];
  final List<ChatSuggestion> _allSuggestions = [
    // Empty Input / General
    ChatSuggestion(text: "Check product availability", icon: Icons.inventory_2_rounded, keywords: []),
    ChatSuggestion(text: "Talk to sales", icon: Icons.headset_mic_rounded, keywords: []),
    ChatSuggestion(text: "Track my order", icon: Icons.local_shipping_rounded, keywords: []),
    ChatSuggestion(text: "Raise complaint", icon: Icons.report_problem_rounded, keywords: []),
    // Price related
    ChatSuggestion(text: "Show price list", icon: Icons.list_alt_rounded, keywords: ["price", "cost", "how much", "rate"]),
    ChatSuggestion(text: "Latest offers", icon: Icons.local_offer_rounded, keywords: ["price", "discount", "offer", "sale"]),
    ChatSuggestion(text: "Discount details", icon: Icons.percent_rounded, keywords: ["price", "discount", "cheap"]),
    // Mobile related
    ChatSuggestion(text: "Available models", icon: Icons.smartphone_rounded, keywords: ["mobile", "phone", "smartphone", "model"]),
    ChatSuggestion(text: "Best phones under 20000", icon: Icons.trending_up_rounded, keywords: ["mobile", "phone", "budget"]),
    ChatSuggestion(text: "Compare phones", icon: Icons.compare_arrows_rounded, keywords: ["mobile", "phone", "compare"]),
    // Repair related
    ChatSuggestion(text: "Screen repair cost", icon: Icons.screen_lock_portrait_rounded, keywords: ["repair", "fix", "screen", "broken"]),
    ChatSuggestion(text: "Battery replacement", icon: Icons.battery_charging_full_rounded, keywords: ["repair", "battery", "charge"]),
    ChatSuggestion(text: "Service center details", icon: Icons.location_on_rounded, keywords: ["repair", "service", "center", "location"]),
  ];

  @override
  void initState() {
    super.initState();
    _initChat();
    _controller.addListener(_onInputChanged);
    _updateSuggestions(""); // Initial suggestions
  }

  @override
  void dispose() {
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _updateSuggestions(_controller.text.trim().toLowerCase());
  }

  void _updateSuggestions(String input) {
    setState(() {
      if (input.isEmpty) {
        _visibleSuggestions = _allSuggestions.where((s) => s.keywords.isEmpty).toList();
      } else {
        _visibleSuggestions = _allSuggestions.where((s) {
          return s.keywords.any((k) => input.contains(k));
        }).toList();
      }
    });
  }

  Future<void> _initChat() async {
    await _loadMessages();
    await _clearUnread();
    _updateStatusToRead();
    _generateRandomLastSeen();
  }

  void _generateRandomLastSeen() {
    setState(() {
      _lastSeen = DateTime.now().minute % 2 == 0 ? "Online" : "Last seen ${DateTime.now().minute % 15 + 1} mins ago";
    });
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('local_chat_${widget.contact.phone}');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        _messages = jsonList.map((e) => LocalMessage.fromJson(e)).toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearUnread() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('support_unread_counts');
    if (data != null) {
      Map<String, dynamic> counts = jsonDecode(data);
      counts[widget.contact.phone] = 0;
      await prefs.setString('support_unread_counts', jsonEncode(counts));
    }
  }

  void _updateStatusToRead() {
    bool changed = false;
    for (var m in _messages) {
      if (m.isMe && m.status != MessageStatus.read) {
        m.status = MessageStatus.read;
        changed = true;
      }
    }
    if (changed) {
      setState(() {});
      _saveMessages();
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_messages.map((e) => e.toJson()).toList());
    await prefs.setString('local_chat_${widget.contact.phone}', data);
  }

  Future<void> _sendMessage({String? customText}) async {
    final text = customText ?? _controller.text.trim();
    if (text.isEmpty) return;

    final newMsg = LocalMessage(text: text, isMe: true, timestamp: DateTime.now(), status: MessageStatus.sent);
    setState(() {
      _messages.add(newMsg);
      if (customText == null) _controller.clear();
    });
    _scrollToBottom();
    _saveMessages();

    // 🔄 Sync with Backend
    try {
      final int myId = widget.currentUserId ?? 1;
      final int targetId = widget.contact.id;

      int? convId = widget.conversationId;
      if (convId == null) {
        // Try to get or create conversation on backend
        convId = await ChatService.getOrCreateConversation(myId, targetId);
      }

      if (convId != null) {
        final sent = await ChatService.sendMessage(convId, myId, text);
        if (sent != null) {
          setState(() {
            newMsg.status = MessageStatus.delivered;
          });
          _saveMessages();
        }
      }
    } catch (e) {
      debugPrint("❌ SYNC ERROR: $e");
      // Fallback: It stays local-only for now
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Text(widget.contact.shopName[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.contact.shopName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(_lastSeen, style: TextStyle(fontSize: 11, color: _lastSeen == "Online" ? Colors.green : Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.videocam_outlined, size: 24)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline_rounded, size: 24)),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildInstagramBubble(_messages[index]),
                ),
          ),
          _buildSuggestions(),
          _buildInstagramInput(),
        ],
      ),
    );
  }

  Widget _buildInstagramBubble(LocalMessage msg) {
    bool isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFF3F4F6),
              child: Text(widget.contact.shopName[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(msg.timestamp),
                        style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 9),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(msg.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 32), // Padding for sent messages
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    Color iconColor = Colors.white70;
    if (status == MessageStatus.read) iconColor = Colors.white;
    
    switch (status) {
      case MessageStatus.sent: return Icon(Icons.done, size: 12, color: iconColor);
      case MessageStatus.delivered: return Icon(Icons.done_all, size: 12, color: iconColor);
      case MessageStatus.read: return Icon(Icons.done_all, size: 12, color: iconColor);
    }
  }

  Widget _buildInstagramInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Message...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: const Text(
                "Send",
                style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_visibleSuggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _visibleSuggestions.length,
        itemBuilder: (context, index) {
          final sug = _visibleSuggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(sug.text, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
              onPressed: () => _sendMessage(customText: sug.text),
            ),
          );
        },
      ),
    );
  }
}
