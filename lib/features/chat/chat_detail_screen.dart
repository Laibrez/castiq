import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatDetailScreen extends StatelessWidget {
  final bool isRequested;
  final bool isLocked;

  const ChatDetailScreen({
    super.key, 
    this.isRequested = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              child: Icon(LucideIcons.user, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(
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
          if (isLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: const Color(0xFF6366F1).withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(LucideIcons.lock, size: 14, color: Color(0xFF818CF8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chat will be enabled once the application is accepted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF818CF8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isRequested)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF141419),
              child: Column(
                children: [
                  const Text(
                    'New Job Request',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fashion Shoot • \$500 • NYC',
                    style: TextStyle(color: Colors.white70),
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
            child: Opacity(
              opacity: isLocked ? 0.3 : 1.0,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: isLocked ? 1 : 20,
                reverse: true,
                itemBuilder: (context, index) {
                  if (isLocked) return const SizedBox.shrink();
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
                      child: const Text(
                        'This is a message text example.',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      enabled: !isLocked,
                      decoration: InputDecoration(
                        hintText: isLocked ? 'Chat locked' : 'Type a message...',
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
                    onPressed: isLocked ? null : () {},
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
