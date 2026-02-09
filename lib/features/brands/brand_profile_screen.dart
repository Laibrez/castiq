import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:flutter_application_1/features/jobs/job_detail_screen.dart';
import 'package:flutter_application_1/features/brands/edit_brand_profile_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class BrandProfileScreen extends StatefulWidget {
  final String? brandId; // Optional: If null, shows the current user's brand profile

  const BrandProfileScreen({super.key, this.brandId});

  @override
  State<BrandProfileScreen> createState() => _BrandProfileScreenState();
}

class _BrandProfileScreenState extends State<BrandProfileScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final targetId = widget.brandId ?? _authService.currentUser?.uid;

    if (targetId == null) {
      return Scaffold(
        backgroundColor: AppTheme.cream,
        body: Center(child: Text('Please log in', style: GoogleFonts.montserrat(color: AppTheme.black))),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(targetId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.cream,
            body: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: AppTheme.cream,
            body: Center(child: Text('Brand not found', style: GoogleFonts.montserrat(color: AppTheme.black))),
          );
        }

        final userData = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

        return Scaffold(
          backgroundColor: AppTheme.cream,
          body: CustomScrollView(
            slivers: [
              // 1. LinkedIn-style Header (Banner + Logo)
              SliverToBoxAdapter(
                child: _buildHeader(userData),
              ),

              // 2. Brand Info & Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData.companyName ?? userData.name,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(LucideIcons.mapPin, size: 14, color: AppTheme.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    userData.location ?? 'Global',
                                    style: GoogleFonts.montserrat(
                                      color: AppTheme.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(LucideIcons.badgeCheck, color: AppTheme.gold, size: 16),
                                ],
                              ),
                            ],
                          ),
                          if (widget.brandId == null) // Edit button only for own profile
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditBrandProfileScreen(userData: userData),
                                  ),
                                ).then((_) => setState(() {})); // Refresh on return
                              },
                              icon: const Icon(LucideIcons.edit3, color: AppTheme.grey, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Stats Bar
                      _buildStatsBar(),
                      const SizedBox(height: 40),

                      // Sections
                      _buildSectionTitle('About'),
                      const SizedBox(height: 12),
                      Text(
                        userData.bio ?? 'A premium brand on Caztiq dedicated to finding the worlds top talent for high-end fashion and commercial projects.',
                        style: GoogleFonts.montserrat(
                          color: AppTheme.grey,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildSectionTitle('Categories'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _categoryChip('Fashion'),
                          _categoryChip('Editorial'),
                          _categoryChip('Runway'),
                          _categoryChip('Commercial'),
                        ],
                      ),
                      const SizedBox(height: 32),

                      _buildSectionTitle('Presence'),
                      const SizedBox(height: 16),
                      _linkItem(LucideIcons.globe, userData.website ?? 'www.${(userData.companyName ?? "brand").toLowerCase().replaceAll(" ", "")}.com'),
                      const SizedBox(height: 12),
                      _linkItem(LucideIcons.instagram, '@${(userData.companyName ?? "brand").toLowerCase().replaceAll(" ", "")}_official'),
                      const SizedBox(height: 40),

                      // Password / Portfolio Preview Section (Visible to Models)
                      if (widget.brandId != null)
                        _buildPortfolioPreviewSection(),
                    ],
                  ),
                ),
              ),

              // 3. Active Job Openings
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Active Job Openings'),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final jobs = [
                        {'title': 'Miami Swim Week 2024', 'info': 'Florida • March 15'},
                        {'title': 'Spring Lookbook Shoot', 'info': 'New York • April 20'},
                      ];
                      return _jobOpeningItem(context, jobs[index]['title']!, jobs[index]['info']!);
                    },
                    childCount: 2,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(user.profileImageUrl ?? 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=2070&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.black.withOpacity(0.2),
                  Colors.transparent,
                  AppTheme.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        // Logo
        Positioned(
          bottom: -40,
          left: 24,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  user.profileImageUrl ?? 'https://ui-avatars.com/api/?name=${user.companyName ?? user.name}&background=random',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        // Back Button (if viewing another brand)
        if (widget.brandId != null)
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: AppTheme.white,
              child: IconButton(
                icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        // Share Button
        Positioned(
          top: 50,
          right: 20,
          child: CircleAvatar(
            backgroundColor: AppTheme.white,
            child: IconButton(
              icon: const Icon(LucideIcons.share, color: AppTheme.black, size: 20),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0DCD5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('Active jobs', '12'),
          _statDivider(),
          _statItem('Bookings', '158'),
          _statDivider(),
          _statItem('Models', '42'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: AppTheme.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFE0DCD5),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.black,
      ),
    );
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE0DCD5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13),
      ),
    );
  }

  Widget _linkItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0DCD5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.grey),
          ),
          const SizedBox(width: 16),
          Text(text, style: GoogleFonts.montserrat(color: AppTheme.black.withOpacity(0.8), fontSize: 14)),
          const Spacer(),
          const Icon(LucideIcons.externalLink, size: 14, color: AppTheme.grey),
        ],
      ),
    );
  }

  Widget _buildPortfolioPreviewSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.lock, color: AppTheme.gold, size: 28),
          const SizedBox(height: 16),
          Text(
            'Password Protected',
            style: GoogleFonts.cormorantGaramond(color: AppTheme.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'This brand requires a password to view their full creative portfolio.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Enter Password', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobOpeningItem(BuildContext context, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        final mockJob = {
          'jobName': title,
          'brandName': 'Vogue Miami',
          'location': subtitle.split(' • ').first,
          'date': subtitle.split(' • ').last,
          'pay': '\$2,500',
          'category': 'Runway',
        };
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailScreen(job: mockJob)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0DCD5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cormorantGaramond(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      color: AppTheme.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppTheme.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
