import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSettingsSection('Profile Settings', [
            _buildSettingsItem(LucideIcons.user, 'Edit Profile Info'),
            _buildSettingsItem(LucideIcons.camera, 'Change Profile Photo'),
          ]),
          const SizedBox(height: 32),
          _buildSettingsSection('Security', [
            _buildSettingsItem(LucideIcons.lock, 'Change Password'),
            _buildSettingsItem(LucideIcons.shieldCheck, 'Two-Factor Authentication'),
          ]),
          const SizedBox(height: 32),
          _buildSettingsSection('Notifications', [
            _buildSettingsItem(LucideIcons.bell, 'Push Notifications'),
            _buildSettingsItem(LucideIcons.mail, 'Email Notifications'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.white70),
      title: Text(title, style: GoogleFonts.inter(fontSize: 16)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.white24),
      onTap: () {},
      contentPadding: EdgeInsets.zero,
    );
  }
}
