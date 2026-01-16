import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/features/portfolio/z_card_screen.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:intl/intl.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final AuthService _authService = AuthService();
  final BookingService bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Please log in', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found', style: TextStyle(color: Colors.white70)));
          }

          final userData = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
          final stats = userData.stats ?? {};

          return CustomScrollView(
            slivers: [
              // 1. Premium Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Photo
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                userData.profileImageUrl ?? 'https://ui-avatars.com/api/?name=${userData.name}&background=random',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Name and Basic Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userData.name,
                                        style: GoogleFonts.lora(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    _IconButton(
                                      icon: LucideIcons.edit3,
                                      onTap: () {
                                        // TODO: Implement Edit navigation
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${stats['age'] ?? '24'} • ${userData.location ?? 'Miami, Florida'}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ZCardScreen(userData: userData),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.contact, size: 14, color: Color(0xFF818CF8)),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'My Z-Card',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF818CF8),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                                      ),
                                      child: Text(
                                        '${stats['experience'] ?? '3'}y exp',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Clean Flashcards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ABOUT CARD
                    _Card(
                      title: 'About',
                      child: Text(
                        userData.bio ?? 'Professional model based in Miami. Specialized in high-fashion editorial and runway. Open to travel for exceptional opportunities.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.65),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // MEASUREMENTS CARD
                    _Card(
                      title: 'Measurements',
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 20,
                        children: [
                          _stat('Height', stats['height'] ?? '5\'10"'),
                          _stat('Bust', stats['bust'] ?? '34"'),
                          _stat('Waist', stats['waist'] ?? '24"'),
                          _stat('Hips', stats['hips'] ?? '35"'),
                          _stat('Shoe', stats['shoes'] ?? '8.5'),
                          _stat('Dress', stats['dress'] ?? '2'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ATTRIBUTES & CATEGORIES CARD
                    _Card(
                      title: 'Attributes & Specialties',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _stat('Eyes', stats['eyes'] ?? 'Blue'),
                              const SizedBox(width: 48),
                              _stat('Hair', stats['hair'] ?? 'Blonde'),
                              const SizedBox(width: 48),
                              _stat('Skin', stats['skin'] ?? 'Fair'),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: Colors.white10),
                          ),
                          Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.4),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (userData.category?.split(',') ?? ['Runway', 'Commercial', 'Editorial', 'Swimwear']).map((cat) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Text(
                                  cat.trim(),
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),

              // 3. Booking History (NEW)
              StreamBuilder<List<BookingModel>>(
                stream: bookingService.getUserBookings(user.uid, 'model'),
                builder: (context, snapshot) {
                  final history = (snapshot.data ?? []).where((b) => ['completed', 'paid'].contains(b.status)).toList();
                  if (history.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 32),
                        Text(
                          'Experience History',
                          style: GoogleFonts.tinos(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...history.take(3).map((booking) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.check, size: 14, color: Colors.green),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.jobTitle ?? 'Model Booking',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMMM yyyy').format(booking.date ?? booking.createdAt),
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.externalLink, size: 14, color: Colors.white24),
                            ],
                          ),
                        )).toList(),
                        if (history.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+ ${history.length - 3} more completed bookings',
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ]),
                    ),
                  );
                },
              ),

              // 4. Portfolio Gallery Header
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 48),
                    Text(
                      'Featured Work',
                      style: GoogleFonts.tinos(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),

              // 5. Grid of Photos
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final images = userData.portfolio ?? [
                        'https://images.unsplash.com/photo-1539109132381-31a0b302653a?q=80&w=400&auto=format&fit=crop',
                        'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=400&auto=format&fit=crop',
                        'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=400&auto=format&fit=crop',
                        'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=400&auto=format&fit=crop',
                      ];
                      
                      if (index >= images.length) return null;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                    childCount: userData.portfolio?.length ?? 4,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.tinos(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6366F1),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
      ),
    );
  }
}
