import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'CAZTIQ',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 20,
            color: Colors.white,
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
            child: const Text(
              'Apply',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
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
                childAspectRatio: 0.65,
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
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Consistent pill style
            ),
          ),
          child: const Text(
            'Apply to Join Caztiq',
            style: TextStyle(
              fontWeight: FontWeight.bold,
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
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
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
                  image: DecorationImage(
                    image: NetworkImage(model.profileImageUrl ??
                        'https://ui-avatars.com/api/?name=${model.name}&background=random'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.lock, size: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          model.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          model.location ?? 'Global',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (model.categories?.isNotEmpty == true ? model.categories!.first : 'Fashion'),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6366F1),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
