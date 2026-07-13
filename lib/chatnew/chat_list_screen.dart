import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import 'support_chat_screen.dart';
import 'chat_constants.dart';

class ChatListScreen extends StatefulWidget {
  final int currentUserId;

  const ChatListScreen({super.key, required this.currentUserId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Conversation> _mergedConversations = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadConversations(isPolling: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool isPolling = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Initial Load from Cache (only if not polling)
    if (!isPolling && _mergedConversations.isEmpty) {
      final String? cachedData = prefs.getString('cached_conversations');
      if (cachedData != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedData);
          setState(() {
            _mergedConversations = decoded.map((j) => Conversation.fromJson(j, widget.currentUserId)).toList();
            _isLoading = false;
          });
        } catch (e) {
          debugPrint("❌ CACHE ERROR: $e");
        }
      }
    }

    // 2. Fetch Backend Conversations
    final backendList = await ChatService.fetchConversations(widget.currentUserId);
    
    // 3. Fetch Local Chats and Merge
    List<Conversation> merged = List.from(backendList);

    for (var contact in ChatConstants.allContacts) {
      final String? chatData = prefs.getString('local_chat_${contact.phone}');
      if (chatData != null) {
        final List<dynamic> messages = jsonDecode(chatData);
        if (messages.isNotEmpty) {
          final lastMsgJson = messages.last;
          final DateTime lastTime = DateTime.parse(lastMsgJson['timestamp']);
          final String lastText = lastMsgJson['text'];

          int existingIndex = merged.indexWhere((c) => c.otherUser.id == contact.id);

          if (existingIndex != -1) {
            if (merged[existingIndex].lastMessageTime == null || 
                lastTime.isAfter(merged[existingIndex].lastMessageTime!)) {
              // Optionally update with local data if newer
            }
          } else {
            merged.add(Conversation(
              id: -1, 
              otherUser: ChatUser(id: contact.id, name: contact.shopName, role: contact.category),
              lastMessage: lastText,
              lastMessageTime: lastTime,
              unreadCount: 0,
            ));
          }
        }
      }
    }

    // 4. Sort by Time (Descending)
    merged.sort((a, b) {
      final t1 = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final t2 = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return t2.compareTo(t1);
    });

    // 5. Update UI and Cache
    if (mounted) {
      setState(() {
        _mergedConversations = merged;
        _isLoading = false;
      });
      // Silent Cache Update
      await prefs.setString('cached_conversations', jsonEncode(merged.map((c) => c.toJson()).toList()));
    }
  }

  void _showNewChatFlow() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Start New Chat", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildNewChatOption(
                    title: "Business",
                    subtitle: "Connect with vendors",
                    icon: Icons.business_center_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(context);
                      _openContactSelection();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNewChatOption(
                    title: "Admin",
                    subtitle: "Get system help",
                    icon: Icons.admin_panel_settings_rounded,
                    color: const Color(0xFFEA580C),
                    onTap: () {
                      Navigator.pop(context);
                      _openContactSelection();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openContactSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportChatScreen(currentUserId: widget.currentUserId),
      ),
    ).then((_) => _loadConversations());
  }

  Widget _buildNewChatOption({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Support Chat", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -1)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded, size: 28)),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _mergedConversations.isEmpty
          ? _buildShimmerEffect()
          : _mergedConversations.isEmpty 
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadConversations(),
                  color: const Color(0xFF2563EB),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _mergedConversations.length,
                    separatorBuilder: (context, index) => const Divider(indent: 84, height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (context, index) {
                      final conv = _mergedConversations[index];
                      return _buildConversationTile(conv);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewChatFlow,
        elevation: 4,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text("New Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.grey[100]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 64, color: const Color(0xFF3B82F6).withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text("No conversations yet", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text("Your support chats will appear here", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv) {
    return ListTile(
      onTap: () {
        final contact = ChatConstants.allContacts.firstWhere(
          (c) => c.id == conv.otherUser.id,
          orElse: () => SupportContact(id: conv.otherUser.id, shopName: conv.otherUser.name, phone: "", address: "", dept: "", category: "Business"),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupportChatDetailScreen(
              contact: contact,
              currentUserId: widget.currentUserId,
              conversationId: conv.id == -1 ? null : conv.id,
            ),
          ),
        ).then((_) => _loadConversations());
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
            child: Center(
              child: Text(
                conv.otherUser.name[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB), fontSize: 20),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
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
              conv.otherUser.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.3),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conv.lastMessageTime != null)
            Text(
              _formatDateTime(conv.lastMessageTime!),
              style: TextStyle(
                fontSize: 12,
                color: conv.unreadCount > 0 ? const Color(0xFF2563EB) : Colors.grey[500],
                fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                conv.lastMessage ?? "Start a conversation",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: conv.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (conv.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Text(
                  conv.unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}



