import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/admin/models/model_profile.dart';
import 'package:flutter_application_1/features/admin/admin_model_detail_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class AdminModelProfilesScreen extends StatefulWidget {
  const AdminModelProfilesScreen({super.key});

  @override
  State<AdminModelProfilesScreen> createState() => _AdminModelProfilesScreenState();
}

class _AdminModelProfilesScreenState extends State<AdminModelProfilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';
  List<ModelProfile> _models = [];
  List<ModelProfile> _filteredModels = [];
  bool _isLoading = true;

  // Mock data for testing
  final List<ModelProfile> _mockModels = [
    ModelProfile(
      id: "mock-model-1",
      userId: "mock-user-1",
      firstName: "Sophia",
      lastName: "Martinez",
      profilePhotoUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400",
      city: "Los Angeles",
      country: "United States",
      categories: ["Runway", "Editorial", "Commercial", "Swimwear"],
      idVerified: false,
      portfolioApproved: false,
      stripeOnboardingComplete: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ModelProfile(
      id: "mock-model-2",
      userId: "mock-user-2",
      firstName: "Emma",
      lastName: "Chen",
      profilePhotoUrl: "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400",
      city: "New York",
      country: "United States",
      categories: ["Commercial", "Fitness", "Lifestyle"],
      idVerified: true,
      portfolioApproved: false,
      stripeOnboardingComplete: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ModelProfile(
      id: "mock-model-3",
      userId: "mock-user-3",
      firstName: "Isabella",
      lastName: "Romano",
      profilePhotoUrl: "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400",
      city: "Milan",
      country: "Italy",
      categories: ["High Fashion", "Runway", "Editorial"],
      idVerified: true,
      portfolioApproved: true,
      stripeOnboardingComplete: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterModels);
    _fetchModels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchModels() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('model_profiles')
          .orderBy('created_at', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        // Use mock data if no real models exist
        setState(() {
          _models = _mockModels;
          _filteredModels = _models;
        });
      } else {
        setState(() {
          _models = snapshot.docs.map((doc) {
            final data = doc.data();
            return ModelProfile.fromFirestore(data, doc.id);
          }).toList();
          _filteredModels = _models;
        });
      }
    } catch (e) {
      // On error, use mock data
      setState(() {
        _models = _mockModels;
        _filteredModels = _models;
      });
    } finally {
      setState(() => _isLoading = false);
      _filterModels();
    }
  }

  void _filterModels() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredModels = _models.where((model) {
        final fullName = '${model.firstName ?? ""} ${model.lastName ?? ""}'.toLowerCase();
        final location = '${model.city ?? ""} ${model.country ?? ""}'.toLowerCase();
        final matchesSearch = 
            fullName.contains(query) ||
            location.contains(query);
        
        switch (_filter) {
          case 'verified':
            return matchesSearch && (model.idVerified == true);
          case 'unverified':
            return matchesSearch && (model.idVerified != true);
          case 'portfolio_pending':
            return matchesSearch && (model.portfolioApproved != true);
          default:
            return matchesSearch;
        }
      }).toList();
    });
  }

  Map<String, int> get _filterCounts {
    return {
      'all': _models.length,
      'verified': _models.where((m) => m.idVerified == true).length,
      'unverified': _models.where((m) => m.idVerified != true).length,
      'portfolio_pending': _models.where((m) => m.portfolioApproved != true).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        title: Text(
          'Models',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Models',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review and manage model registrations',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE8E4DE)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search by name or location...',
                              hintStyle: TextStyle(color: AppTheme.grey),
                              prefixIcon: const Icon(LucideIcons.search, color: AppTheme.grey, size: 18),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E4DE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFilterButton('all', 'All'),
                            _buildFilterButton('verified', 'Verified'),
                            _buildFilterButton('unverified', 'Unverified'),
                            _buildFilterButton('portfolio_pending', 'Portfolio pending'),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8E4DE)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search by name or location...',
                            hintStyle: TextStyle(color: AppTheme.grey),
                            prefixIcon: const Icon(LucideIcons.search, color: AppTheme.grey, size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E4DE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildFilterButton('all', 'All')),
                            Expanded(child: _buildFilterButton('verified', 'Verified')),
                            Expanded(child: _buildFilterButton('unverified', 'Unverified')),
                            Expanded(child: _buildFilterButton('portfolio_pending', 'Pending')),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Model List
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(64),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredModels.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(64),
                  child: Text(
                    'No models found',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                ),
              )
            else
              ..._filteredModels.map((model) => _buildModelCard(model)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String value, String label) {
    final isSelected = _filter == value;
    final count = _filterCounts[value] ?? 0;
    
    return InkWell(
      onTap: () {
        setState(() {
          _filter = value;
        });
        _filterModels();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(ModelProfile model) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminModelDetailScreen(modelId: model.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E4DE)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: model.profilePhotoUrl != null
                  ? NetworkImage(model.profilePhotoUrl!)
                  : null,
              child: model.profilePhotoUrl == null
                  ? Text(
                      '${model.firstName?[0] ?? ""}${model.lastName?[0] ?? ""}'.toUpperCase(),
                      style: const TextStyle(fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Name and Location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${model.firstName ?? ""} ${model.lastName ?? ""}'.trim(),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (model.idVerified == true)
                        const Icon(
                          LucideIcons.checkCircle2,
                          size: 16,
                          color: Colors.green,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.city != null && model.country != null
                        ? '${model.city}, ${model.country}'
                        : model.country ?? 'Location not set',
                    style: TextStyle(
                      color: AppTheme.grey,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Categories (hidden on small screens)
            if (MediaQuery.of(context).size.width > 600) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...(model.categories.take(2).map((cat) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E4DE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: AppTheme.grey,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }) ?? []),
                  if ((model.categories.length ?? 0) > 2)
                    Text(
                      '+${(model.categories.length ?? 0) - 2}',
                      style: TextStyle(
                        color: AppTheme.grey,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
            ],
            
            // Portfolio Status
            if (MediaQuery.of(context).size.width > 600) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (model.portfolioApproved == true) ? Colors.green : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (model.portfolioApproved == true) ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color: AppTheme.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
            
            // Chevron
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppTheme.grey,
            ),
          ],
        ),
      ),
    );
  }
}
