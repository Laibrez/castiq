import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/features/chat/chat_detail_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  Stream<QuerySnapshot> _buildChatStream() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE0DCD5)),
                  ),
                  child: const Icon(LucideIcons.edit, size: 20, color: AppTheme.black),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0DCD5)),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.montserrat(color: AppTheme.black),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: GoogleFonts.montserrat(color: AppTheme.grey),
                  prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppTheme.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Chats List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildChatStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.messageSquare, size: 48, color: AppTheme.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: GoogleFonts.montserrat(color: AppTheme.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final chatDoc = snapshot.data!.docs[index];
                    final chatData = chatDoc.data() as Map<String, dynamic>;
                    return _ChatTile(
                      chatId: chatDoc.id,
                      chatData: chatData,
                      currentUserId: _authService.currentUser!.uid,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String chatId;
  final Map<String, dynamic> chatData;
  final String currentUserId;

  const _ChatTile({
    required this.chatId,
    required this.chatData,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> participants = chatData['participants'] ?? [];
    final String otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    // Determines if the last message was read by the current user
    bool hasUnread = false;
    final lastMessageSenderId = chatData['lastMessageSenderId'];
    final isRead = chatData['isRead'] ?? true;
    
    if (lastMessageSenderId != currentUserId && !isRead) {
      hasUnread = true;
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final otherUserName = userData?['name'] ?? 'User';
        final otherUserImage = userData?['profileImageUrl'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chatId: chatId,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserImage: otherUserImage,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasUnread 
                  ? AppTheme.gold.withOpacity(0.05) 
                  : AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasUnread 
                    ? AppTheme.gold.withOpacity(0.3) 
                    : const Color(0xFFE0DCD5),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.cream,
                      backgroundImage: otherUserImage != null 
                        ? NetworkImage(otherUserImage) 
                        : null,
                      child: otherUserImage == null 
                        ? Text(otherUserName[0], style: GoogleFonts.cormorantGaramond(color: AppTheme.black, fontWeight: FontWeight.bold, fontSize: 20)) 
                        : null,
                    ),
                    if (userData?['isOnline'] == true)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            otherUserName,
                            style: GoogleFonts.cormorantGaramond(
                              color: AppTheme.black,
                              fontSize: 18,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(chatData['lastMessageTime']),
                            style: GoogleFonts.montserrat(
                              color: hasUnread ? AppTheme.gold : AppTheme.grey,
                              fontSize: 12,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chatData['lastMessage'] ?? 'Started a conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: hasUnread ? AppTheme.black : AppTheme.grey,
                          fontSize: 14,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final time = timestamp.toDate();
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
