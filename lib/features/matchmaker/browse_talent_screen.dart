import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/auth/role_selection_screen.dart';

class BrowseTalentScreen extends StatelessWidget {
  const BrowseTalentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Realistic Mock Data for "Fake" profiles preview
    final List<UserModel> mockModels = [
      UserModel(
        uid: 'm1',
        name: 'Sasha Meyer',
        email: 'sasha@example.com',
        role: 'model',
        location: 'Paris, FR',
        category: 'Fashion',
        profileImageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'm2',
        name: 'Jordan Blake',
        email: 'jordan@example.com',
        role: 'model',
        location: 'New York, US',
        category: 'Commercial',
        profileImageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'm3',
        name: 'Elena Rossi',
        email: 'elena@example.com',
        role: 'model',
        location: 'Milan, IT',
        category: 'Beauty',
        profileImageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'm4',
        name: 'Marcus Chen',
        email: 'marcus@example.com',
        role: 'model',
        location: 'London, UK',
        category: 'Fitness',
        profileImageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'm5',
        name: 'Zoe Kravitz',
        email: 'zoe@example.com',
        role: 'model',
        location: 'Los Angeles, US',
        category: 'Editorial',
        profileImageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'm6',
        name: 'David Gandy',
        email: 'david@example.com',
        role: 'model',
        location: 'London, UK',
        category: 'Fashion',
        profileImageUrl: 'https://images.unsplash.com/photo-1488161628813-04466f872be2?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'm7',
        name: 'Lina Zhang',
        email: 'lina@example.com',
        role: 'model',
        location: 'Tokyo, JP',
        category: 'Runway',
        profileImageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'm8',
        name: 'Xavier Woods',
        email: 'xavier@example.com',
        role: 'model',
        location: 'Berlin, DE',
        category: 'Streetwear',
        profileImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'm9',
        name: 'Maya Angelou',
        email: 'maya@example.com',
        role: 'model',
        location: 'Nairobi, KE',
        category: 'Editorial',
        profileImageUrl: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'm10',
        name: 'Hiroshi Sato',
        email: 'hiroshi@example.com',
        role: 'model',
        location: 'Seoul, KR',
        category: 'Lifestyle',
        profileImageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=400&auto=format&fit=crop',
        createdAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Caztiq',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontSize: 26,
            color: AppTheme.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
              );
            },
            child: Text(
              'Apply',
              style: GoogleFonts.montserrat(
                color: AppTheme.gold,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.6,
              ),
              itemCount: mockModels.length,
              itemBuilder: (context, index) {
                return _ReadOnlyModelCard(model: mockModels[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border(
            top: BorderSide(color: AppTheme.grey.withOpacity(0.15)),
            ),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: AppTheme.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Apply to Join Caztiq',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Fashion', 'Commercial', 'Beauty', 'Fitness'];
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? AppTheme.gold : const Color(0xFFE0DCD5),
              ),
            ),
            child: Center(
              child: Text(
                categories[index],
                style: GoogleFonts.montserrat(
                  color: isSelected ? AppTheme.black : AppTheme.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReadOnlyModelCard extends StatelessWidget {
  final UserModel model;

  const _ReadOnlyModelCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E4DE)),
                  image: DecorationImage(
                    image: NetworkImage(model.profileImageUrl ??
                        'https://ui-avatars.com/api/?name=${model.name}&background=random'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Lock icon overlay — indicates preview-only
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.lock, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          model.name,
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppTheme.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          model.location ?? 'Global',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          (model.categories?.isNotEmpty == true ? model.categories!.first : 'Fashion'),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: AppTheme.gold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
