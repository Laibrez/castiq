import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/matchmaker/create_job_screen.dart';
import 'package:flutter_application_1/features/profile/model_profile_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/models/user_model.dart';

class ModelDiscoveryScreen extends StatelessWidget {
  const ModelDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search models...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(LucideIcons.slidersHorizontal),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF1A1A1A),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => const _FilterBottomSheet(),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'model')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                final models = docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

                if (models.isEmpty) {
                  return Center(
                    child: Text(
                      'No models found.',
                      style: GoogleFonts.tinos(color: Colors.white54, fontSize: 18),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    return _ModelCard(model: models[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobScreen()),
          );
        },
        label: const Text('Post Job'),
        icon: const Icon(LucideIcons.plus),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: GoogleFonts.tinos(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Category',
            style: GoogleFonts.tinos(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(label: 'Fashion', isSelected: true),
              _FilterChip(label: 'Commercial'),
              _FilterChip(label: 'Fitness'),
              _FilterChip(label: 'Runway'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Location',
            style: GoogleFonts.tinos(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Enter city or region',
              prefixIcon: Icon(LucideIcons.mapPin, size: 18),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected ? Colors.white : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: Colors.grey[800]!)),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final UserModel model;

  const _ModelCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ModelProfileScreen(model: model)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(model.profileImageUrl ?? 'https://ui-avatars.com/api/?name=${model.name}&background=random'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    style: GoogleFonts.tinos(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    model.location ?? 'Location not set',
                    style: GoogleFonts.tinos(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.category ?? 'Fashion',
                    style: GoogleFonts.tinos(
                      fontSize: 12,
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '4.9',
                        style: GoogleFonts.tinos(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
