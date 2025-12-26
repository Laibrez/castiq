import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/contract/contract_screen.dart';

class ChatDetailScreen extends StatelessWidget {
  final bool isRequested;

  const ChatDetailScreen({super.key, this.isRequested = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              child: Icon(LucideIcons.user, size: 20),
              // backgroundImage: NetworkImage('https://source.unsplash.com/random/100x100/?face'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Name',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moreVertical),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (isRequested)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF141419),
              child: Column(
                children: [
                  Text(
                    'New Job Request',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fashion Shoot • \$500 • NYC',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Job Declined')),
                            );
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Move to Active
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const ChatDetailScreen(isRequested: false)),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Job Accepted! Chat moved to Active.')),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 20,
              reverse: true,
              itemBuilder: (context, index) {
                final isMe = index % 2 == 0;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF6366F1) : const Color(0xFF141419),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isMe ? const Radius.circular(0) : null,
                        bottomLeft: !isMe ? const Radius.circular(0) : null,
                      ),
                    ),
                    child: Text(
                      'This is a message text example.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.plus),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF1A1A1A),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(LucideIcons.fileText, color: Colors.white),
                              title: Text('Send Contract', style: GoogleFonts.inter(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(context);
                                // Navigate to Contract Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ContractScreen()),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(LucideIcons.dollarSign, color: Colors.white),
                              title: Text('Send Offer', style: GoogleFonts.inter(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(context);
                                // Show Offer Dialog
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF141419),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.send),
                    color: const Color(0xFF6366F1),
                    onPressed: () {},
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
