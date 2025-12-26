import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/chat/chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Messages',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(),
            indicatorColor: const Color(0xFF6366F1),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Requested'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ChatList(isActive: true),
            _ChatList(isActive: false),
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final bool isActive;

  const _ChatList({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: isActive ? 8 : 3,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withOpacity(0.1)),
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(isRequested: !isActive),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Stack(
            children: [
              const CircleAvatar(
                radius: 24,
                child: Icon(LucideIcons.user, size: 24),
                // backgroundImage: NetworkImage('https://source.unsplash.com/random/100x100/?face'),
              ),
              if (isActive && index < 2)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0A0F), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            isActive ? 'Model Name $index' : 'Brand Name $index',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            isActive ? 'Sure, I can make it!' : 'New Job Request: Fashion Shoot',
            style: GoogleFonts.inter(
              color: (isActive && index < 2) ? Colors.white : Colors.white70,
              fontWeight: (isActive && index < 2) ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '10:30 AM',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              if (isActive && index < 2) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '2',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
