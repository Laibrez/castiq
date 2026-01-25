import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/models/chat_model.dart';
import 'package:flutter_application_1/core/services/chat_service.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  final String userRole; // 'model' or 'brand'

  const ChatScreen({super.key, required this.chat, required this.userRole});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  // Preset quick reply options
  final List<String> _quickReplies = [
    'Hello! 👋',
    'Let\'s schedule a shoot',
    'Can you send your portfolio?',
    'I\'m interested!',
    'What are your rates?',
  ];

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _chatService.markMessagesAsRead(widget.chat.id, userId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _otherPartyName {
    return widget.userRole == 'model' ? widget.chat.brandName : widget.chat.modelName;
  }

  String? get _otherPartyImage {
    return widget.userRole == 'model' ? widget.chat.brandImage : widget.chat.modelImage;
  }

  Future<void> _sendMessage([String? customMessage]) async {
    final content = customMessage ?? _messageController.text.trim();
    if (content.isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    final userName = widget.userRole == 'model' 
        ? widget.chat.modelName 
        : widget.chat.brandName;

    final success = await _chatService.sendMessage(
      chatId: widget.chat.id,
      senderId: user.uid,
      senderName: userName,
      senderRole: widget.userRole,
      content: content,
    );

    setState(() => _isSending = false);

    if (success) {
      _messageController.clear();
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: _otherPartyImage != null
                  ? NetworkImage(_otherPartyImage!)
                  : null,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
              child: _otherPartyImage == null
                  ? Text(
                      _otherPartyName[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherPartyName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.chat.jobTitle != null)
                    Text(
                      widget.chat.jobTitle!,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chat.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF818CF8)));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.messageSquare, size: 48, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text(
                          'Start the conversation',
                          style: TextStyle(color: Colors.white.withOpacity(0.3)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final showDate = index == 0 || 
                        !_isSameDay(messages[index - 1].timestamp, message.timestamp);

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _formatDate(message.timestamp),
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                            ),
                          ),
                        _MessageBubble(message: message, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Quick Replies
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _quickReplies.map((reply) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _sendMessage(reply),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      reply,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Input Field
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0a0a0a),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSending ? null : () => _sendMessage(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSending ? Colors.white.withOpacity(0.1) : const Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.white.withOpacity(0.9),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? LucideIcons.checkCheck : LucideIcons.check,
                    size: 14,
                    color: message.isRead ? Colors.white : Colors.white.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
