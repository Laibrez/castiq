import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/core/widgets/application_confirmation_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/brands/brand_profile_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // 1. Large Cover Image Header
          SliverAppBar(
            expandedHeight: 350,
            backgroundColor: Colors.black,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    job['coverImage'],
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
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
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Brand Logo & View Profile Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            job['brandLogo'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job['brandName'],
                              style: GoogleFonts.tinos(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Premium Partner',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.5),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BrandProfileScreen(
                                brandId: job['brandId'],
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'View Brand Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 3. Job Title
                  Text(
                    job['jobName'],
                    style: GoogleFonts.tinos(
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Highlighted Info Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _infoRow(LucideIcons.mapPin, 'Location', '${job['location']} – Miami Beach Convention Center'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Colors.white10),
                        ),
                        _infoRow(LucideIcons.calendar, 'Dates', job['date']),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Colors.white10),
                        ),
                        _infoRow(LucideIcons.dollarSign, 'Total Payment', '${job['payment']} USD', isHighlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 5. Sections
                  _sectionHeader('Description'),
                  const SizedBox(height: 12),
                  Text(
                    'Join Vogue Miami for the most anticipated runway event of the season. Featuring a global cast of exceptional talent, Miami Swim Week 2024 represents a pinnacle of fashion and high-energy performance. Models will be showcasing our lead swim collection across a 4-day intensive schedule.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _sectionHeader('Requirements'),
                  const SizedBox(height: 12),
                  _requirementItem('Height: 5\'9" – 6\'0"'),
                  _requirementItem('Strong runway walk with personality'),
                  _requirementItem('Available for casting and rehearsals March 12-14'),
                  _requirementItem('Professional attitude and reliability'),
                  const SizedBox(height: 32),

                  _sectionHeader('Past Events'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _mediaCard('https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=400&auto=format&fit=crop'),
                        _mediaCard('https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=400&auto=format&fit=crop'),
                        _mediaCard('https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=400&auto=format&fit=crop'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            ApplicationConfirmationModal.show(context, jobName: job['jobName']);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Apply Now',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: isHighlight ? const Color(0xFF818CF8) : Colors.white,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.tinos(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _requirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaCard(String imageUrl) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
