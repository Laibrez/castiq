import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class ZCardScreen extends StatelessWidget {
  final UserModel userData;

  const ZCardScreen({super.key, required this.userData});

  // Generate unique Z-Card URL
  String get zCardUrl => 'https://castiq-d85d4.web.app/zcard/${userData.uid}';

  void _shareZCard(BuildContext context) async {
    final result = await Share.share(
      'Check out my professional Z-Card on Caztiq!\n\n$zCardUrl',
      subject: '${userData.name} - Z-Card',
    );

    if (result.status == ShareResultStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Z-Card shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: zCardUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Z-Card link copied to clipboard!'),
        backgroundColor: AppTheme.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = userData.stats ?? {};
    final images = userData.portfolio ?? [
      'https://images.unsplash.com/photo-1539109132381-31a0b302653a?q=80&w=600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=400&auto=format&fit=crop',
    ];

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MY Z-CARD',
          style: GoogleFonts.montserrat(
            color: AppTheme.black,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.share2, color: AppTheme.black, size: 20),
            color: AppTheme.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'share') {
                _shareZCard(context);
              } else if (value == 'copy') {
                _copyLink(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(LucideIcons.share2, size: 18, color: AppTheme.black.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Text('Share Z-Card', style: GoogleFonts.montserrat(color: AppTheme.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(LucideIcons.copy, size: 18, color: AppTheme.black.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Text('Copy Link', style: GoogleFonts.montserrat(color: AppTheme.black)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header: "Z-Card" Description
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Text(
                'Professional Z-Card showcasing your best images and measurements. Share with agencies or brands.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppTheme.grey,
                  height: 1.5,
                ),
              ),
            ),

            // The Z-Card Component (High-Fidelity)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Main Large Photo
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      child: Image.network(
                        images[0],
                        height: 450,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    
                    // Small Support Photos
                    if (images.length > 1)
                      Row(
                        children: images.skip(1).take(2).map((img) => Expanded(
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.white, width: 2),
                            ),
                            child: Image.network(img, fit: BoxFit.cover),
                          ),
                        )).toList(),
                      ),

                    // Measurement Detail Plate
                    Container(
                      padding: const EdgeInsets.all(32),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData.name.toUpperCase(),
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.black,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    userData.location ?? 'MIAMI, FL',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.grey,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              // Subtle Branding
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'CAZTIQ',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.black.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Stats Grid
                          Wrap(
                            spacing: 32,
                            runSpacing: 16,
                            children: [
                              _zStat('HEIGHT', stats['height'] ?? '5\'10"'),
                              _zStat('BUST', stats['bust'] ?? '34'),
                              _zStat('WAIST', stats['waist'] ?? '24'),
                              _zStat('HIPS', stats['hips'] ?? '35'),
                              _zStat('SHOES', stats['shoes'] ?? '8.5'),
                              _zStat('EYES', stats['eyes'] ?? 'BLUE'),
                              _zStat('HAIR', stats['hair'] ?? 'BLONDE'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
            
            // Reorder Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0DCD5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mousePointer2, size: 18, color: AppTheme.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Your Z-Card uses the first 3 photos from your portfolio. Reorder your gallery to change them.',
                        style: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.black.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _zStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppTheme.black.withOpacity(0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toString().toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.black,
          ),
        ),
      ],
    );
  }
}
