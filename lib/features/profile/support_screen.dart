import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'How can we help?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          _buildSupportItem(
            icon: LucideIcons.mail,
            title: 'Email Support',
            subtitle: 'support@castiq.com',
            onTap: () {},
          ),
          _buildSupportItem(
            icon: LucideIcons.helpCircle,
            title: 'FAQ',
            subtitle: 'Read our frequently asked questions',
            onTap: () {},
          ),
          _buildSupportItem(
            icon: LucideIcons.fileText,
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            onTap: () {},
          ),
          _buildSupportItem(
            icon: LucideIcons.shield,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141419),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(LucideIcons.chevronRight, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        tileColor: const Color(0xFF0A0A0B),
      ),
    );
  }
}
