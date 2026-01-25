import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/models/chat_model.dart';
import 'package:flutter_application_1/core/services/chat_service.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/features/chat/chat_screen.dart';
import 'package:intl/intl.dart';

class ChatsListScreen extends StatefulWidget {
  final String userRole; // 'model' or 'brand'

  const ChatsListScreen({super.key, required this.userRole});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Please log in', style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Messages',
          style: GoogleFonts.tinos(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatService.getUserChats(userId, widget.userRole),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF818CF8)));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.messageSquare, size: 64, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 24),
                  Text(
                    'Messages are locked',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      widget.userRole == 'model'
                          ? 'Chat becomes active once you accept a brand invitation or a job offer.'
                          : 'Chat becomes active once a model accepts your offer.',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _ChatTile(
                chat: chat,
                userRole: widget.userRole,
                currentUserId: userId,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chat: chat, userRole: widget.userRole),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String userRole;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.userRole,
    required this.currentUserId,
    required this.onTap,
  });

  String get _otherPartyName {
    return userRole == 'model' ? chat.brandName : chat.modelName;
  }

  String? get _otherPartyImage {
    return userRole == 'model' ? chat.brandImage : chat.modelImage;
  }

  bool get _hasUnread {
    return chat.unreadCount > 0 && chat.lastMessageSenderId != currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hasUnread 
              ? const Color(0xFF6366F1).withOpacity(0.1) 
              : const Color(0xFF161618),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasUnread 
                ? const Color(0xFF6366F1).withOpacity(0.3) 
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: _otherPartyImage != null
                      ? NetworkImage(_otherPartyImage!)
                      : null,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                  child: _otherPartyImage == null
                      ? Text(
                          _otherPartyName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                if (_hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${chat.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _otherPartyName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: _hasUnread ? FontWeight.bold : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: TextStyle(
                          color: _hasUnread 
                              ? const Color(0xFF818CF8) 
                              : Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (chat.jobTitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      chat.jobTitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    chat.lastMessage,
                    style: TextStyle(
                      color: _hasUnread 
                          ? Colors.white.withOpacity(0.8) 
                          : Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: _hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              LucideIcons.chevronRight,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return DateFormat('h:mm a').format(time);
    } else if (diff.inDays < 7) {
      return DateFormat('EEE').format(time);
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}
