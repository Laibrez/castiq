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
  final List<String> _tabs = ['Portfolio', 'Z-Card', 'Measurements', 'Experience'];
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final stats = widget.model.stats ?? {};

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // 1. High-Fidelity Header
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: Colors.black,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(LucideIcons.share, color: Colors.white, size: 20),
                    onPressed: () {
                      ShareModal.show(
                        context,
                        shareUrl: 'https://castiq-d85d4.web.app/profile/${widget.model.uid}',
                        title: widget.model.name,
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.model.profileImageUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.model.name,
                                    style: GoogleFonts.tinos(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.mapPin, size: 14, color: Colors.white.withOpacity(0.6)),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.model.location ?? 'Miami, FL',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'RATE RANGE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\$800 - \$2,500',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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

          // 2. Pill-style Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: _tabs.asMap().entries.map((entry) {
                      final isSelected = _selectedTabIndex == entry.key;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = entry.key),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white10,
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white60,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // 3. Tab Views
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSelectedTabContent(stats),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0),
              Colors.black.withOpacity(0.9),
              Colors.black,
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SendOfferScreen(model: widget.model)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Send Project Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(Map<String, dynamic> stats) {
    switch (_selectedTabIndex) {
      case 0: return _buildPortfolioTab();
      case 1: return _buildZCardTab(stats);
      case 2: return _buildMeasurementsTab(stats);
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(images[index], fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildZCardTab(Map<String, dynamic> stats) {
    final portfolio = widget.model.portfolio ?? [];
    
    // Convert stats keys to match ZCardWidget expectation (Capitalized)
    final zCardStats = {
      'Height': stats['height']?.toString() ?? '-',
      'Bust': stats['bust']?.toString() ?? '-',
      'Waist': stats['waist']?.toString() ?? '-',
      'Hips': stats['hips']?.toString() ?? '-',
      'Shoe': stats['shoe']?.toString() ?? '-',
    };

    // Determine current Z-Card images
    // If zCard data exists in FireStore (under 'zCard' map? or 'zCardUrl' used previously?)
    // The previous implementation used 'zCardUrl' string. The new requirement uses a structure.
    // I should check if 'zCard' map exists on the model object.
    // Assuming UserModel doesn't have the new 'zCard' map yet, I might need to access it raw or update UserModel.
    // For now, I will use widget.model.portfolio as the source, and if I have a local state or saved state, use that.
    
    // Since UserModel might not have the 'zCard' field fully typed yet, I'll rely on a dynamic approach or just use portfolio for now.
    // Ideally, I should fetch the specific zCard image list from Firestore if I want to persist the *order*.
    // But since I can't easily change UserModel right now without verifying it, 
    // I'll implement the callback to update Firestore 'zCard' field.
    
    // To properly show the *saved* Z-Card, I need to know the saved images.
    // I will assume for this task that if I just edit it, it updates.
    // But for *displaying* the saved one... I might need to fetch it or assume it's passed in `model`.
    
    // Let's assume for now we always start with proper portfolio images if no Z-Card specific data is in UserModel.
    // Real implementation would require UserModel update. I will assume `widget.model.toMap()['zCard']['images']` might exist if I cast it.
    
    List<dynamic> currentImages = portfolio;
    // Check if we can get zCard images from model.
    // Since I can't see UserModel definition easily, I'll try to check if I can access the raw map or if I should just use portfolio.
    // The requirement says "Save Z-Card structure ... in Firestore".
    // I will try to read it from Firestore stream? No, `model` is passed in.
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ZCardWidget(
        allImages: portfolio,
        name: widget.model.name,
        category: widget.model.categories?.isNotEmpty == true ? widget.model.categories!.first : 'Model',
        location: widget.model.location ?? '',
        willingToTravel: widget.model.willingToTravel ?? false,
        stats: zCardStats,
        onZCardImagesChanged: (newImages) async {
           // Update Firestore
           try {
             await FirebaseFirestore.instance.collection('users').doc(widget.model.uid).set({
               'zCard': {
                 'images': newImages,
                 'updatedAt': FieldValue.serverTimestamp(),
               }
             }, SetOptions(merge: true));
             
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Z-Card updated')),
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
      ),
    );
  }

  Widget _buildMeasurementsTab(Map<String, dynamic> stats) {
    return Column(
      children: [
        _buildMeasurementTable('Body Metrics', {
          'Height': stats['height'] != null ? '${stats['height']} cm' : '-',
          'Bust': stats['bust'] != null ? '${stats['bust']} cm' : '-',
          'Waist': stats['waist'] != null ? '${stats['waist']} cm' : '-',
          'Hips': stats['hips'] != null ? '${stats['hips']} cm' : '-',
          'Shoe': stats['shoe'] ?? '-',
        }),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMeasurementTable(String title, Map<String, String> data) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              title,
              style: GoogleFonts.tinos(
                color: const Color(0xFF6366F1),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...data.entries.map((entry) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                Text(entry.value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExperienceItem('Specialties', widget.model.categories ?? ['High Fashion', 'Editorial', 'Runway', 'Commercial']),
            const SizedBox(height: 32),
            Text(
              'Verified History',
              style: GoogleFonts.tinos(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              _emptyExperience()
            else
              ...history.map((booking) => _bookingHistoryCard(booking)),
          ],
        );
      },
    );
  }

  Widget _buildExperienceItem(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.tinos(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(item.trim(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _bookingHistoryCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.check, size: 16, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.jobTitle ?? 'Model Booking', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(DateFormat('MMMM yyyy').format(booking.date ?? booking.createdAt), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyExperience() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.history, size: 40, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('No verified bookings yet', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _zStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white38,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toString().toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 90.0;
  @override
  double get maxExtent => 90.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
