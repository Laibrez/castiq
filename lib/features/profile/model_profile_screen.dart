import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/booking/booking_request_screen.dart';
import 'package:flutter_application_1/features/chat/chat_detail_screen.dart';

class ModelProfileScreen extends StatelessWidget {
  const ModelProfileScreen({super.key});

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
                'https://source.unsplash.com/random/400x600/?model',
                fit: BoxFit.cover,
              ),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
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
                            'Jane Doe',
                            style: GoogleFonts.tinos(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Text(
                            '24 years old • New York, NY',
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
                      _StatItem(label: 'Height', value: "5'9\""),
                      _StatItem(label: 'Bust', value: '34"'),
                      _StatItem(label: 'Waist', value: '24"'),
                      _StatItem(label: 'Hips', value: '35"'),
                      _StatItem(label: 'Shoes', value: '8'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Physical & Characteristics',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(label: 'Eyes', value: 'Blue'),
                      _StatItem(label: 'Hair', value: 'Blonde'),
                      _StatItem(label: 'Skin', value: 'Fair'),
                      _StatItem(label: 'Dress', value: '4'),
                    ],
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
                      _Chip(label: 'Editorial'),
                      _Chip(label: 'Commercial'),
                      _Chip(label: 'Runway'),
                      _Chip(label: 'UGC'),
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
                    'Professional fashion and commercial model with 5 years of experience. Available for photoshoots, runway, and brand campaigns. Passionate about sustainable fashion and artistic expression.',
                    style: GoogleFonts.tinos(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Walk Video',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: NetworkImage('https://source.unsplash.com/random/800x400/?runway'),
                        fit: BoxFit.cover,
                        opacity: 0.7,
                      ),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.playCircle, color: Colors.white, size: 64),
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
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage('https://source.unsplash.com/random/200x200/?fashion,model&sig=$index'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100), // Space for bottom button
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatDetailScreen(isRequested: true)),
                      );
                    },
                    child: const Text('Make an Offer'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
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
              ],
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
