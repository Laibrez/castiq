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
    // Mark messages as read when entering the screen
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'isRead': true,
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    // Add message to subcollection
    await chatRef.collection('messages').add({
      'senderId': currentUserId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    // Update chat document
    await chatRef.update({
      'lastMessage': messageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
      'isRead': false,
    });

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.otherUserName,
          style: GoogleFonts.cormorantGaramond(
            color: AppTheme.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moreVertical, color: AppTheme.black),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE0DCD5), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello to ${widget.otherUserName}!',
                      style: GoogleFonts.montserrat(color: AppTheme.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final messageDoc = snapshot.data!.docs[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == _authService.currentUser?.uid;

                    // Check if we need to show date separator
                    bool showDate = false;
                    if (index == snapshot.data!.docs.length - 1) {
                      showDate = true;
                    } else {
                      final nextMessageData = snapshot.data!.docs[index + 1].data() as Map<String, dynamic>;
                      final currentTimestamp = messageData['timestamp'] as Timestamp?;
                      final nextTimestamp = nextMessageData['timestamp'] as Timestamp?;
                      
                      if (currentTimestamp != null && nextTimestamp != null) {
                        final currentDate = currentTimestamp.toDate();
                        final nextDate = nextTimestamp.toDate();
                        if (currentDate.day != nextDate.day || 
                            currentDate.month != nextDate.month || 
                            currentDate.year != nextDate.year) {
                          showDate = true;
                        }
                      }
                    }

                    return Column(
                      children: [
                        if (showDate && messageData['timestamp'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _formatDateHeader((messageData['timestamp'] as Timestamp).toDate()),
                              style: GoogleFonts.montserrat(
                                color: AppTheme.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        _MessageBubble(
                          message: messageData['text'] ?? '',
                          isMe: isMe,
                          timestamp: messageData['timestamp'],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              border: const Border(top: BorderSide(color: Color(0xFFE0DCD5))),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.plus, color: AppTheme.grey),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cream,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE0DCD5)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.montserrat(color: AppTheme.black),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.montserrat(color: AppTheme.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.black, // Changed from Gold to Black for better contrast/elegance
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.send, color: AppTheme.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inDays == 0 && now.day == date.day) {
      return 'Today';
    } else if (now.difference(date).inDays == 1 || (now.day - date.day == 1 && now.month == date.month)) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final Timestamp? timestamp;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.black : AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe 
              ? null 
              : Border.all(color: const Color(0xFFE0DCD5)),
          boxShadow: isMe 
              ? [BoxShadow(color: AppTheme.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
              : [BoxShadow(color: AppTheme.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: GoogleFonts.montserrat(
                color: isMe ? AppTheme.white : AppTheme.black,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  DateFormat.jm().format(timestamp!.toDate()),
                  style: GoogleFonts.montserrat(
                    color: isMe ? AppTheme.white.withOpacity(0.7) : AppTheme.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
