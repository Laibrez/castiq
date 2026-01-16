import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/job_service.dart';
import 'package:flutter_application_1/core/models/job_model.dart';
import 'package:flutter_application_1/features/profile/model_profile_screen.dart';

class ModelDiscoveryScreen extends StatefulWidget {
  const ModelDiscoveryScreen({super.key});

  @override
  State<ModelDiscoveryScreen> createState() => _ModelDiscoveryScreenState();
}

class _ModelDiscoveryScreenState extends State<ModelDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search models...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        prefixIcon: const Icon(LucideIcons.search, size: 20, color: Colors.white24),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showFilterSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: const Icon(LucideIcons.slidersHorizontal, size: 20, color: Colors.white),
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
                _quickFilter('All Models', isSelected: true),
                _quickFilter('Available Now'),
                _quickFilter('Top Rated'),
                _quickFilter('Newly Joined'),
              ],
            ),
          ),

          // Models Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'model')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.users, size: 48, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text('No models found', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                      ],
                    ),
                  );
                }

                final models = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1, // Flashcards look better as full-width list items or large cards
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

  Widget _quickFilter(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white60,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
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
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Filters',
                style: GoogleFonts.tinos(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              _filterSection('Category', ['Fashion', 'Commercial', 'Editorial', 'Runway', 'Fitness']),
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
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) => _multiSelectChip(opt)).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _multiSelectChip(String label) {
    bool isSelected = false; // Mock state
    return StatefulBuilder(
      builder: (context, setState) => GestureDetector(
        onTap: () => setState(() => isSelected = !isSelected),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : Colors.white10,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF818CF8) : Colors.white60,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, UserModel model) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
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
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$800 - \$2,500 / day',
                      style: const TextStyle(
                        color: Colors.white,
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
                      backgroundColor: Colors.white,
                      child: const Icon(LucideIcons.mail, color: Colors.black, size: 20),
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
                          style: GoogleFonts.tinos(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 12, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(
                              model.location ?? 'Global',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: [
                            _miniChip(model.category ?? 'Fashion'),
                            _miniChip('Editorial'),
                          ],
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
                      backgroundColor: Colors.white.withOpacity(0.05),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Profile'),
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
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF818CF8),
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
                style: GoogleFonts.tinos(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Select Job for ${widget.model.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('No active jobs to invite to', style: TextStyle(color: Colors.white38))),
                );
              }
              return Container(
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
                          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.transparent),
                        ),
                        child: Center(child: Text(job.title, style: TextStyle(color: isSelected ? const Color(0xFF818CF8) : Colors.white70))),
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
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _msgController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedJob == null ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Send Invitation', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
