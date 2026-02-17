import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:flutter_application_1/features/profile/model_profile_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class ModelDiscoveryScreen extends StatefulWidget {
  const ModelDiscoveryScreen({super.key});

  @override
  State<ModelDiscoveryScreen> createState() => _ModelDiscoveryScreenState();
}

class _ModelDiscoveryScreenState extends State<ModelDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  // Filter State
  List<String> _selectedCategories = [];
  RangeValues _ageRange = const RangeValues(18, 45);
  String? _selectedLocation;
  
  // Sorting State
  String _sortOption = 'Newest'; // Options: 'Newest', 'Highest Rated'

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'model');

    if (_selectedCategories.isNotEmpty) {
      query = query.where('categories', arrayContainsAny: _selectedCategories);
    }

    if (_selectedLocation != null && _selectedLocation != 'Global') {
      query = query.where('location', isEqualTo: _selectedLocation);
    }

    // Age filtering: Firebase allows range on one field only.
    // Since we are not using range on other fields, this is fine.
    query = query.where('age', isGreaterThanOrEqualTo: _ageRange.start.toInt());
    query = query.where('age', isLessThanOrEqualTo: _ageRange.end.toInt());

    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0DCD5)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.montserrat(color: AppTheme.black),
                      decoration: InputDecoration(
                        hintText: 'Search models...',
                        hintStyle: GoogleFonts.montserrat(color: AppTheme.grey),
                        prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppTheme.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (text) {
                        setState(() {}); // Trigger rebuild to filter locally if needed, or update query
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showFilterSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (_selectedCategories.isNotEmpty || _selectedLocation != null) 
                        ? AppTheme.gold : const Color(0xFFE0DCD5)),
                    ),
                    child: Icon(LucideIcons.slidersHorizontal, size: 20, 
                      color: (_selectedCategories.isNotEmpty || _selectedLocation != null) 
                        ? AppTheme.gold : AppTheme.black),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Quick Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _quickFilter('All Models', isSelected: _selectedLocation == null && _selectedCategories.isEmpty, onTap: () {
                  setState(() {
                    _selectedLocation = null;
                    _selectedCategories = [];
                  });
                }),
                _quickFilter('Miami', isSelected: _selectedLocation == 'Miami', onTap: () {
                  setState(() => _selectedLocation = 'Miami');
                }),
                _quickFilter('Editorial', isSelected: _selectedCategories.contains('Editorial'), onTap: () {
                  setState(() {
                    if (_selectedCategories.contains('Editorial')) {
                      _selectedCategories.remove('Editorial');
                    } else {
                      _selectedCategories.add('Editorial');
                    }
                  });
                }),
                _quickFilter('Runway', isSelected: _selectedCategories.contains('Runway'), onTap: () {
                  setState(() {
                    if (_selectedCategories.contains('Runway')) {
                      _selectedCategories.remove('Runway');
                    } else {
                      _selectedCategories.add('Runway');
                    }
                  });
                }),
              ],
            ),
          ),

          // Sorting Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Results', style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0DCD5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortOption,
                      dropdownColor: AppTheme.white,
                      icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.grey),
                      style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: 13),
                      isDense: true,
                      items: ['Newest', 'Highest Rated'].map((opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(opt),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _sortOption = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Models Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.users, size: 48, color: AppTheme.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('No models match your filters', style: GoogleFonts.montserrat(color: AppTheme.grey)),
                        if (_selectedCategories.isNotEmpty || _selectedLocation != null) 
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategories = [];
                                _selectedLocation = null;
                                _ageRange = const RangeValues(18, 45);
                              });
                            },
                            child: Text('Clear Filters', style: GoogleFonts.montserrat(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                }

                var models = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                // Client-side text search if needed (Firestore doesn't do full-text natively well)
                if (_searchController.text.isNotEmpty) {
                  models = models.where((m) => m.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                }

                // Client-side sorting
                if (_sortOption == 'Newest') {
                  models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                } else if (_sortOption == 'Highest Rated') {
                  models.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1, 
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: models.length,
                  itemBuilder: (context, index) => _ModelFlashcard(
                    model: models[index],
                    onInvite: () => _showInviteDialog(context, models[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickFilter(String label, {bool isSelected = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.black : AppTheme.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE0DCD5)),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isSelected ? AppTheme.white : AppTheme.grey,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Filters',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 32),
              _filterSection('Category', ['Fashion', 'Commercial', 'Editorial', 'Runway', 'Fitness'], isMulti: true),
              
              Text(
                'Age Range',
                style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setSheetState) => Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_ageRange.start.toInt()} years', style: GoogleFonts.montserrat(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('${_ageRange.end.toInt()} years', style: GoogleFonts.montserrat(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 16,
                      max: 65,
                      divisions: 49,
                      activeColor: AppTheme.gold,
                      inactiveColor: AppTheme.grey.withOpacity(0.2),
                      onChanged: (values) {
                        setSheetState(() => _ageRange = values);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _filterSection('Location', ['Miami', 'New York', 'Los Angeles', 'London', 'Paris']),
              _filterSection('Skin Tone', ['Fair', 'Medium', 'Olive', 'Dark', 'Deep']),
              _filterSection('Eye Color', ['Brown', 'Blue', 'Green', 'Hazel', 'Grey']),
              _filterSection('Height', ['5\'7" - 5\'9"', '5\'9" - 5\'11"', '5\'11"+']),
              _filterSection('Availability', ['Available Now', 'Next 30 Days', 'Next 90 Days']),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.black,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Apply Filters', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterSection(String title, List<String> options, {bool isMulti = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            bool isSelected;
            if (title == 'Location') {
              isSelected = _selectedLocation == opt;
            } else {
              isSelected = _selectedCategories.contains(opt);
            }
            return _multiSelectChip(opt, isSelected, () {
              setState(() {
                if (title == 'Location') {
                  _selectedLocation = (_selectedLocation == opt) ? null : opt;
                } else {
                  if (_selectedCategories.contains(opt)) {
                    _selectedCategories.remove(opt);
                  } else {
                    _selectedCategories.add(opt);
                  }
                }
              });
            });
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _multiSelectChip(String label, bool isSelected, VoidCallback onTap) {
    return StatefulBuilder(
      builder: (context, setSheetState) => GestureDetector(
        onTap: () {
          onTap();
          setSheetState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.gold.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.gold : const Color(0xFFE0DCD5),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: isSelected ? AppTheme.gold : AppTheme.grey,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, UserModel model) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => _InviteBottomSheet(model: model),
    );
  }
}

class _ModelFlashcard extends StatelessWidget {
  final UserModel model;
  final VoidCallback onInvite;

  const _ModelFlashcard({required this.model, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE0DCD5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image Section
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    model.profileImageUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                ),
                // Rate Tag
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$800 - \$2,500 / day',
                      style: GoogleFonts.montserrat(
                        color: AppTheme.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Quick Action
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: onInvite,
                    child: CircleAvatar(
                      backgroundColor: AppTheme.white,
                      child: const Icon(LucideIcons.mail, color: AppTheme.black, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Info Section
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.name,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 12, color: AppTheme.grey),
                            const SizedBox(width: 4),
                            Text(
                              model.location ?? 'Global',
                              style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13),
                            ),
                            if (model.age != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                '${model.age} yrs',
                                style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (model.categories != null && model.categories!.isNotEmpty)
                            ? model.categories!.take(2).map((c) => _miniChip(c)).toList()
                            : [_miniChip('Fashion')],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ModelProfileScreen(model: model)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.black,
                      foregroundColor: AppTheme.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('View Profile', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: AppTheme.gold,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InviteBottomSheet extends StatefulWidget {
  final UserModel model;

  const _InviteBottomSheet({required this.model});

  @override
  State<_InviteBottomSheet> createState() => _InviteBottomSheetState();
}

class _InviteBottomSheetState extends State<_InviteBottomSheet> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  JobModel? _selectedJob;
  final TextEditingController _msgController = TextEditingController(text: "Hi! We'd love to invite you to our upcoming project. Your portfolio is exactly what we're looking for.");

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invite to Job',
                style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.black),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: AppTheme.grey)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Select Job for ${widget.model.name}',
            style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          StreamBuilder<List<JobModel>>(
            stream: _jobService.getBrandJobs(_authService.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final jobs = snapshot.data ?? [];
              if (jobs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0DCD5)),
                  ),
                  child: Center(child: Text('No active jobs to invite to', style: GoogleFonts.montserrat(color: AppTheme.grey))),
                );
              }
              return SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final isSelected = _selectedJob?.id == job.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedJob = job),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.black : AppTheme.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE0DCD5)),
                        ),
                        child: Center(child: Text(job.title, style: GoogleFonts.montserrat(color: isSelected ? AppTheme.white : AppTheme.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
                      ),
                    );
                  }
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          Text(
            'Invitation Message',
            style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _msgController,
            maxLines: 3,
            style: GoogleFonts.montserrat(color: AppTheme.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0DCD5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0DCD5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.black)),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedJob == null ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.black,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Send Invitation', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
