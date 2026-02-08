import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:flutter_application_1/features/bookings/send_offer_screen.dart';
import 'package:flutter_application_1/core/widgets/share_modal.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/core/services/booking_service.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';
import 'package:flutter_application_1/features/auth/widgets/z_card_widget.dart';

class ModelProfileScreen extends StatefulWidget {
  final UserModel model;

  const ModelProfileScreen({super.key, required this.model});

  @override
  State<ModelProfileScreen> createState() => _ModelProfileScreenState();
}

class _ModelProfileScreenState extends State<ModelProfileScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Z-CARD', 'PORTFOLIO', 'MEASUREMENTS', 'HISTORY'];
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final stats = widget.model.stats ?? {};

    return Scaffold(
      backgroundColor: Colors.white, // Editorial white background
      body: CustomScrollView(
        slivers: [
          // 1. Editorial Header
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share, color: Colors.black, size: 20),
                onPressed: () {
                  ShareModal.show(
                    context,
                    shareUrl: 'https://castiq-d85d4.web.app/profile/${widget.model.uid}',
                    title: widget.model.name,
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.model.profileImageUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  // Subtle gradient only at very bottom for text readability if needed, but keeping it minimal
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 150,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 32,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.model.name.toUpperCase(),
                          style: GoogleFonts.didactGothic(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              widget.model.location?.toUpperCase() ?? 'MIAMI, FL',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                              ),
                              child: Text(
                                '\$800 - \$2.5K', // Simplified rate
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
            ),
          ),

          // 2. Minimal Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Column(
                  children: [
                    const Divider(height: 1, color: Colors.black12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _tabs.asMap().entries.map((entry) {
                          final isSelected = _selectedTabIndex == entry.key;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTabIndex = entry.key),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: isSelected ? const Border(bottom: BorderSide(color: Colors.black, width: 2)) : null,
                              ),
                              child: Text(
                                entry.value,
                                style: GoogleFonts.inter(
                                  color: isSelected ? Colors.black : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.black12),
                  ],
                ),
              ),
            ),
          ),

          // 3. Tab Views
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _buildSelectedTabContent(stats),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SendOfferScreen(model: widget.model)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // Sharp editorial button
            elevation: 0,
          ),
          child: Text(
            'SEND BOOKING OFFER',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(Map<String, dynamic> stats) {
    switch (_selectedTabIndex) {
      case 0: return _buildZCardTab(stats);
      case 1: return _buildPortfolioTab(); // Swapped order, Z-Card is primary
      case 2: return _buildMeasurementTable(stats);
      case 3: return _buildExperienceTab();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildPortfolioTab() {
    final images = widget.model.portfolio ?? [
      'https://images.unsplash.com/photo-1539109132381-31a0b302653a?q=80&w=400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=400&auto=format&fit=crop',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7, // Portrait images
        ),
        itemCount: images.length,
        itemBuilder: (context, index) => Image.network(images[index], fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildZCardTab(Map<String, dynamic> stats) {
    final portfolio = widget.model.portfolio ?? [];
    
    final zCardStats = {
      'Height': stats['height']?.toString() ?? '-',
      'Bust': stats['bust']?.toString() ?? '-',
      'Waist': stats['waist']?.toString() ?? '-',
      'Hips': stats['hips']?.toString() ?? '-',
      'Shoe': stats['shoe']?.toString() ?? '-',
    };
    
    return ZCardWidget(
      allImages: portfolio,
      name: widget.model.name,
      category: widget.model.categories?.isNotEmpty == true ? widget.model.categories!.first : 'Model',
      location: widget.model.location ?? '',
      willingToTravel: widget.model.willingToTravel ?? false,
      stats: zCardStats,
      onZCardImagesChanged: (newImages) async {
         try {
           await FirebaseFirestore.instance.collection('users').doc(widget.model.uid).set({
             'zCard': {
               'images': newImages,
               'updatedAt': FieldValue.serverTimestamp(),
             }
           }, SetOptions(merge: true));
           
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Z-Card saved')),
             );
           }
         } catch (e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Failed to save: $e')),
             );
           }
         }
      },
    );
  }

  Widget _buildMeasurementTable(Map<String, dynamic> stats) {
    final data = {
      'Height': stats['height'] != null ? '${stats['height']} cm' : '-',
      'Bust': stats['bust'] != null ? '${stats['bust']} cm' : '-',
      'Waist': stats['waist'] != null ? '${stats['waist']} cm' : '-',
      'Hips': stats['hips'] != null ? '${stats['hips']} cm' : '-',
      'Shoe': stats['shoe'] ?? '-',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MEASUREMENTS',
            style: GoogleFonts.didactGothic(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 24),
          ...data.entries.map((entry) => Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  entry.value,
                  style: GoogleFonts.didactGothic(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildExperienceTab() {
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.getUserBookings(widget.model.uid, 'model'),
      builder: (context, snapshot) {
        final history = (snapshot.data ?? []).where((b) => ['completed', 'paid'].contains(b.status)).toList();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VERIFIED HISTORY',
                style: GoogleFonts.didactGothic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),
              if (history.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'No verified bookings yet',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                )
              else
                ...history.map((booking) => _bookingHistoryItem(booking)),
            ],
          ),
        );
      },
    );
  }

  Widget _bookingHistoryItem(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.jobTitle?.toUpperCase() ?? 'JOB',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM yyyy').format(booking.date ?? booking.createdAt),
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const Icon(LucideIcons.checkCircle2, size: 16, color: Colors.black),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 50.0;
  @override
  double get maxExtent => 50.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
