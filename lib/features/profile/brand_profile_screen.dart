import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrandProfileScreen extends StatefulWidget {
  const BrandProfileScreen({super.key});

  @override
  State<BrandProfileScreen> createState() => _BrandProfileScreenState();
}

class _BrandProfileScreenState extends State<BrandProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Brand data not found')));
        }

        final userData = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        
        if (!_isEditing) {
          _nameController.text = userData.companyName ?? userData.name;
          _locationController.text = userData.location ?? '';
          _bioController.text = userData.bio ?? '';
          _websiteController.text = userData.website ?? '';
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, userData),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBrandInfo(userData),
                      const SizedBox(height: 24),
                      _buildStats(),
                      const SizedBox(height: 24),
                      _buildAboutSection(userData),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Past Campaigns'),
                      const SizedBox(height: 16),
                      _buildCampaignsGrid(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Reviews'),
                      const SizedBox(height: 16),
                      _buildReviewsList(),
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

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(user.profileImageUrl ?? 'https://images.unsplash.com/photo-1545959795-ac52120898e4?q=80&w=2071&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ),
        // Edit Profile Button
        Positioned(
          top: 60,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: Icon(_isEditing ? LucideIcons.save : LucideIcons.edit2, color: Colors.white),
              onPressed: () async {
                if (_isEditing) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                    'companyName': _nameController.text.trim(),
                    'location': _locationController.text.trim(),
                    'bio': _bioController.text.trim(),
                    'website': _websiteController.text.trim(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated')));
                }
                setState(() => _isEditing = !_isEditing);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandInfo(UserModel user) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(labelText: 'Brand Name'),
            )
          else
            Row(
              children: [
                Text(
                  user.companyName ?? user.name,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.badgeCheck, color: Color(0xFF6366F1), size: 20),
              ],
            ),
          const SizedBox(height: 8),
          if (_isEditing)
            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white54),
              decoration: const InputDecoration(labelText: 'Location'),
            )
          else
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 16, color: Colors.white54),
                const SizedBox(width: 6),
                Text(
                  user.location ?? 'Location not set',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('0', 'Jobs Posted'),
          _buildVerticalDivider(),
          _buildStatItem('0', 'Hires'),
          _buildVerticalDivider(),
          _buildStatItem('5.0', 'Rating', icon: LucideIcons.star),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {IconData? icon}) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: Colors.amber),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white12,
    );
  }

  Widget _buildAboutSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About'),
        const SizedBox(height: 12),
        if (_isEditing)
          TextField(
            controller: _bioController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white70),
            decoration: const InputDecoration(labelText: 'About the Brand'),
          )
        else
          Text(
            user.bio ?? 'No description provided.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        const SizedBox(height: 16),
        if (_isEditing)
          TextField(
            controller: _websiteController,
            style: const TextStyle(color: Color(0xFF6366F1)),
            decoration: const InputDecoration(labelText: 'Website'),
          )
        else
          Row(
            children: [
              _buildSocialLink(LucideIcons.globe, user.website ?? 'No website'),
            ],
          ),
      ],
    );
  }

  Widget _buildSocialLink(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            color: const Color(0xFF6366F1),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignsGrid() {
    return Center(child: Text('No campaigns yet', style: TextStyle(color: Colors.white24)));
  }

  Widget _buildReviewsList() {
    return Center(child: Text('No reviews yet', style: TextStyle(color: Colors.white24)));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}
