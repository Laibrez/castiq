import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/booking/booking_request_screen.dart';
import 'package:flutter_application_1/features/chat/chat_detail_screen.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:flutter_application_1/features/booking/send_offer_screen.dart';

class ModelProfileScreen extends StatelessWidget {
  final UserModel model;

  const ModelProfileScreen({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                model.profileImageUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000&auto=format&fit=crop',
                fit: BoxFit.cover,
              ),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SendOfferScreen(model: model)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Send Offer'),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
                            model.name,
                            style: GoogleFonts.tinos(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Text(
                            '${model.location ?? "Location not set"}',
                            style: GoogleFonts.tinos(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.star, size: 16, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              '4.9',
                              style: GoogleFonts.tinos(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(label: 'Height', value: model.stats?['height'] ?? "5'9\""),
                      _StatItem(label: 'Bust', value: model.stats?['bust'] ?? '34"'),
                      _StatItem(label: 'Waist', value: model.stats?['waist'] ?? '24"'),
                      _StatItem(label: 'Hips', value: model.stats?['hips'] ?? '35"'),
                      _StatItem(label: 'Shoes', value: model.stats?['shoes'] ?? '8'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Availability',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    model.availability ?? 'Flexible availability. Contact for specific dates.',
                    style: GoogleFonts.tinos(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Experience',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(label: model.category ?? 'Editorial'),
                      _Chip(label: 'Commercial'),
                      _Chip(label: 'Runway'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'About',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    model.bio ?? 'Professional model available for brand campaigns and artistic projects.',
                    style: GoogleFonts.tinos(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Portfolio',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: model.portfolio?.length ?? 6,
                    itemBuilder: (context, index) {
                      final imageUrl = model.portfolio != null 
                          ? model.portfolio![index] 
                          : 'https://source.unsplash.com/random/200x200/?fashion,model&sig=$index';
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border(top: BorderSide(color: Colors.grey[900]!)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatDetailScreen()),
                );
              },
              child: const Text('Chat'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Text(
        label,
        style: GoogleFonts.tinos(fontSize: 14),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.tinos(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tinos(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
