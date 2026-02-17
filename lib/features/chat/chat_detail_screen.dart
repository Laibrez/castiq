import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/services/chat_service.dart';
import 'package:flutter_application_1/core/models/chat_model.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final bool isLocked;

  const ChatDetailScreen({
    super.key, 
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    this.isLocked = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      // Mark messages as read when entering the screen
      _chatService.markMessagesAsRead(widget.chatId, _currentUserId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Optimistic UI update could be done here, but stream is fast enough usually
    
    await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: _currentUserId,
      senderName: 'User', // Ideally fetch current user name or pass it in
      senderRole: 'unknown', // Backend functions might handle this or we fetch it
      content: text,
    );
    
    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // List is reversed
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.cream,
              backgroundImage: widget.otherUserImage != null 
                ? NetworkImage(widget.otherUserImage!) 
                : null,
              child: widget.otherUserImage == null 
                ? const Icon(LucideIcons.user, size: 20, color: AppTheme.black)
                : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                Text(
                  'Active', // Could be real status if we had presence system
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moreVertical, color: AppTheme.black),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE8E4DE), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          if (widget.isLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: AppTheme.cream,
              child: Row(
                children: [
                  const Icon(LucideIcons.lock, size: 14, color: AppTheme.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chat is currently locked.',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppTheme.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.black));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: GoogleFonts.montserrat(color: AppTheme.grey),
                    ),
                  );
                }

                final messages = snapshot.data!;
                // Reverse is handled by ListView if we insert at 0? 
                // ChatService returns orderBy timestamp ascending.
                // We want oldest at top if not reversed, or newest at bottom.
                // Standard chat: newest at bottom. ListView(reverse: true) means index 0 is bottom.
                // So we need to reverse the list or use reverse: true and sort DESC.
                // ChatService sorts ASC (oldest first).
                // So for reverse: true (bottom up), we need DESC (newest first).
                // Let's reverse the list here.
                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: reversedMessages.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = reversedMessages[index];
                    final isMe = message.senderId == _currentUserId;
                    final showDate = index == reversedMessages.length - 1 || 
                        reversedMessages[index + 1].timestamp.day != message.timestamp.day;

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              DateFormat('MMM d, yyyy').format(message.timestamp),
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: AppTheme.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMe ? AppTheme.black : AppTheme.white,
                              border: isMe ? null : Border.all(color: const Color(0xFFE8E4DE)),
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isMe ? const Radius.circular(0) : null,
                                bottomLeft: !isMe ? const Radius.circular(0) : null,
                              ),
                              boxShadow: isMe ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ] : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content,
                                  style: GoogleFonts.montserrat(
                                    color: isMe ? AppTheme.white : AppTheme.black,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat('h:mm a').format(message.timestamp),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        color: isMe ? Colors.white54 : AppTheme.grey,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        message.isRead ? LucideIcons.checkCheck : LucideIcons.check,
                                        size: 10,
                                        color: Colors.white54,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              border: Border(top: BorderSide(color: const Color(0xFFE8E4DE))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.plus, color: AppTheme.grey),
                    onPressed: widget.isLocked ? null : () {
                      // Attachment logic
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !widget.isLocked,
                      style: GoogleFonts.montserrat(color: AppTheme.black),
                      decoration: InputDecoration(
                        hintText: widget.isLocked ? 'Chat locked' : 'Type a message...',
                        hintStyle: GoogleFonts.montserrat(color: AppTheme.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE8E4DE)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE8E4DE)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.black),
                        ),
                        filled: true,
                        fillColor: AppTheme.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.send),
                    color: AppTheme.black,
                    onPressed: widget.isLocked ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
