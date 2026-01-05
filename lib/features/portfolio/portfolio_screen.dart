import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/auth/role_selection_screen.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _heightController = TextEditingController();
  final _bustController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _shoesController = TextEditingController();
  final _eyesController = TextEditingController();
  final _hairController = TextEditingController();
  final _skinController = TextEditingController();
  final _dressController = TextEditingController();
  final _aboutController = TextEditingController();

  void _populateControllers(UserModel user) {
    _nameController.text = user.name;
    _locationController.text = user.location ?? '';
    _aboutController.text = user.bio ?? '';
    if (user.stats != null) {
      _ageController.text = user.stats!['age']?.toString() ?? '';
      _heightController.text = user.stats!['height']?.toString() ?? '';
      _bustController.text = user.stats!['bust']?.toString() ?? '';
      _waistController.text = user.stats!['waist']?.toString() ?? '';
      _hipsController.text = user.stats!['hips']?.toString() ?? '';
      _shoesController.text = user.stats!['shoes']?.toString() ?? '';
      _eyesController.text = user.stats!['eyes']?.toString() ?? '';
      _hairController.text = user.stats!['hair']?.toString() ?? '';
      _skinController.text = user.stats!['skin']?.toString() ?? '';
      _dressController.text = user.stats!['dress']?.toString() ?? '';
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw 'User not found';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'bio': _aboutController.text.trim(),
        'stats': {
          'age': _ageController.text.trim(),
          'height': _heightController.text.trim(),
          'bust': _bustController.text.trim(),
          'waist': _waistController.text.trim(),
          'hips': _hipsController.text.trim(),
          'shoes': _shoesController.text.trim(),
          'eyes': _eyesController.text.trim(),
          'hair': _hairController.text.trim(),
          'skin': _skinController.text.trim(),
          'dress': _dressController.text.trim(),
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('User data not found')));
        }

        final userData = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        
        if (!_isEditing) {
          _populateControllers(userData);
        }

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isLoading)
                      const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    TextButton.icon(
                      icon: Icon(_isEditing ? LucideIcons.save : LucideIcons.edit2, size: 18),
                      label: Text(_isEditing ? 'Save' : 'Edit'),
                      onPressed: _isLoading ? null : () {
                        if (_isEditing) {
                          _saveProfile();
                        }
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                    ),
                  ],
                ),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(userData.profileImageUrl ?? 'https://ui-avatars.com/api/?name=${userData.name}&background=random'),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Basic Info'),
                const SizedBox(height: 16),
                _buildTextField('Name', _nameController),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Age', _ageController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Location', _locationController)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Physical Attributes'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Height', _heightController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Bust', _bustController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Waist', _waistController)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Hips', _hipsController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Shoes', _shoesController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Dress Size', _dressController)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Eyes', _eyesController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Hair', _hairController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Skin', _skinController)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Experience & About'),
                const SizedBox(height: 16),
                _buildTextField('About', _aboutController, maxLines: 4),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChip('Editorial'),
                    _buildChip('Commercial'),
                    _buildChip('Runway'),
                    _buildChip('UGC'),
                    if (_isEditing)
                      ActionChip(
                        label: const Icon(LucideIcons.plus, size: 16),
                        onPressed: () {},
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Walk Video'),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141419),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: _isEditing
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.uploadCloud, size: 48, color: Color(0xFF6366F1)),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Video',
                                style: GoogleFonts.inter(color: const Color(0xFF6366F1)),
                              ),
                            ],
                          )
                        : const Icon(LucideIcons.playCircle, size: 64, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Portfolio'),
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
                  itemCount: userData.portfolio?.length ?? 0,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141419),
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(userData.portfolio![index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: _isEditing
                          ? Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(LucideIcons.x, color: Colors.red, size: 16),
                                onPressed: () {},
                              ),
                            )
                          : null,
                    );
                  },
                ),
                if (userData.portfolio == null || userData.portfolio!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No photos in portfolio yet', style: GoogleFonts.inter(color: Colors.white54))),
                  ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.upload),
                        label: const Text('Upload Photos'),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFF141419),
      labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      side: BorderSide(color: Colors.white.withOpacity(0.1)),
    );
  }
}

