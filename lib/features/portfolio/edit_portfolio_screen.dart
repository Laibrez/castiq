import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/media_upload_service.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class EditPortfolioScreen extends StatefulWidget {
  final UserModel userData;

  const EditPortfolioScreen({super.key, required this.userData});

  @override
  State<EditPortfolioScreen> createState() => _EditPortfolioScreenState();
}

class _EditPortfolioScreenState extends State<EditPortfolioScreen> {
  final _formKey = GlobalKey<FormState>();
  final MediaUploadService _uploadService = MediaUploadService();
  final AuthService _authService = AuthService();

  // Text Controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _heightController;
  late TextEditingController _bustController;
  late TextEditingController _waistController;
  late TextEditingController _hipsController;
  late TextEditingController _shoesController;
  late TextEditingController _eyesController;
  late TextEditingController _hairController;

  // State
  bool _isSaving = false;
  String _saveStatus = '';
  List<String> _selectedCategories = [];
  List<String> _portfolioImages = [];
  String? _portfolioVideo;
  String? _profileImageUrl;

  final List<String> _availableCategories = [
    'Fashion', 'Commercial', 'Editorial', 'Runway', 'Fitness', 'Lifestyle', 'Beauty', 'Plus Size'
  ];

  @override
  void initState() {
    super.initState();
    final stats = widget.userData.stats ?? {};
    
    _nameController = TextEditingController(text: widget.userData.name);
    _bioController = TextEditingController(text: widget.userData.bio ?? '');
    _locationController = TextEditingController(text: widget.userData.location ?? '');
    _heightController = TextEditingController(text: stats['height']?.toString() ?? '');
    _bustController = TextEditingController(text: stats['bust']?.toString() ?? '');
    _waistController = TextEditingController(text: stats['waist']?.toString() ?? '');
    _hipsController = TextEditingController(text: stats['hips']?.toString() ?? '');
    _shoesController = TextEditingController(text: stats['shoes']?.toString() ?? '');
    _eyesController = TextEditingController(text: stats['eyes']?.toString() ?? '');
    _hairController = TextEditingController(text: stats['hair']?.toString() ?? '');
    
    _selectedCategories = List<String>.from(widget.userData.categories ?? []);
    _portfolioImages = List<String>.from(widget.userData.portfolioImages ?? widget.userData.portfolio ?? []);
    _portfolioVideo = widget.userData.portfolioVideo;
    _profileImageUrl = widget.userData.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _heightController.dispose();
    _bustController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _shoesController.dispose();
    _eyesController.dispose();
    _hairController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isSaving = true;
      _saveStatus = 'Saving changes...';
    });

    try {
      // Build stats map
      final stats = {
        'height': _heightController.text,
        'bust': _bustController.text,
        'waist': _waistController.text,
        'hips': _hipsController.text,
        'shoes': _shoesController.text,
        'eyes': _eyesController.text,
        'hair': _hairController.text,
      };

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text,
        'bio': _bioController.text,
        'location': _locationController.text,
        'categories': _selectedCategories,
        'stats': stats,
        'portfolioImages': _portfolioImages,
        'portfolioVideo': _portfolioVideo,
        'profileImageUrl': _profileImageUrl,
        'portfolio': _portfolioImages, // Keep backward compatibility
      });

      setState(() {
        _isSaving = false;
        _saveStatus = 'Changes saved successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Portfolio updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to previous screen after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context, true);
      });

    } catch (e) {
      setState(() {
        _isSaving = false;
        _saveStatus = 'Failed to save changes';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addImages() async {
    final images = await _uploadService.pickMultipleImages();
    if (images.isEmpty) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isSaving = true;
      _saveStatus = 'Uploading images...';
    });

    // Pass XFile directly now, DO NOT convert to File(path) for Web support
    final urls = await _uploadService.uploadMultipleImages(
      userId: userId,
      imageFiles: images, // Passing List<XFile>
      onProgress: (completed, total) {
        setState(() => _saveStatus = 'Uploading image $completed of $total...');
      },
    );

    setState(() {
      _portfolioImages.addAll(urls);
      _isSaving = false;
      _saveStatus = '${urls.length} images added!';
    });
  }

  Future<void> _changeProfileImage() async {
    final image = await _uploadService.pickImage();
    if (image == null) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isSaving = true;
      _saveStatus = 'Uploading profile picture...';
    });

    final url = await _uploadService.uploadSingleImage(
      userId: userId,
      imageFile: image,
      folder: 'profiles',
      onProgress: (progress) {
        setState(() => _saveStatus = 'Uploading profile picture... ${(progress * 100).toInt()}%');
      },
    );

    if (url != null) {
      setState(() {
        _profileImageUrl = url;
        _isSaving = false;
        _saveStatus = 'Profile picture updated!';
      });
    } else {
      setState(() {
        _isSaving = false;
        _saveStatus = 'Failed to upload profile picture';
      });
    }
  }

  Future<void> _addVideo() async {
    final video = await _uploadService.pickVideo();
    if (video == null) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isSaving = true;
      _saveStatus = 'Uploading video...';
    });

    // Pass XFile directly
    final url = await _uploadService.uploadVideo(
      userId: userId,
      videoFile: video, 
      onProgress: (progress) {
        setState(() => _saveStatus = 'Uploading video... ${(progress * 100).toInt()}%');
      },
    );

    if (url != null) {
      setState(() {
        _portfolioVideo = url;
        _isSaving = false;
        _saveStatus = 'Video uploaded!';
      });
    } else {
      setState(() {
        _isSaving = false;
        _saveStatus = 'Failed to upload video';
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _portfolioImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Portfolio',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold),
                  )
                : Text('Save', style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE0DCD5), height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Status Banner
            if (_saveStatus.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: _saveStatus.contains('success') || _saveStatus.contains('added') || _saveStatus.contains('uploaded') || _saveStatus.contains('updated')
                      ? Colors.green.withOpacity(0.1)
                      : AppTheme.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (_isSaving)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.black),
                      )
                    else
                      Icon(
                        _saveStatus.contains('Failed') ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
                        color: _saveStatus.contains('Failed') ? Colors.red : Colors.green,
                        size: 18,
                      ),
                    const SizedBox(width: 12),
                    Text(_saveStatus, style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: 13)),
                  ],
                ),
              ),

             // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.white,
                      border: Border.all(color: const Color(0xFFE0DCD5)),
                      image: _profileImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_profileImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImageUrl == null
                        ? const Icon(LucideIcons.user, size: 40, color: AppTheme.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isSaving ? null : _changeProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.white, width: 2),
                        ),
                        child: const Icon(LucideIcons.camera, size: 16, color: AppTheme.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Basic Info Section
            _sectionTitle('Basic Information'),
            _textField('Name', _nameController, validator: (v) => v!.isEmpty ? 'Required' : null),
            _textField('Location', _locationController),
            _textField('Bio', _bioController, maxLines: 4),

            const SizedBox(height: 32),

            // Categories Section
            _sectionTitle('Categories'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((cat) {
                final isSelected = _selectedCategories.contains(cat);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(cat);
                      } else {
                        _selectedCategories.add(cat);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.black : AppTheme.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.black : const Color(0xFFE0DCD5),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.montserrat(
                        color: isSelected ? AppTheme.white : AppTheme.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Measurements Section
            _sectionTitle('Measurements'),
            Row(
              children: [
                Expanded(child: _textField('Height', _heightController)),
                const SizedBox(width: 12),
                Expanded(child: _textField('Bust', _bustController)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _textField('Waist', _waistController)),
                const SizedBox(width: 12),
                Expanded(child: _textField('Hips', _hipsController)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _textField('Shoes', _shoesController)),
                const SizedBox(width: 12),
                Expanded(child: _textField('Eyes', _eyesController)),
              ],
            ),
            _textField('Hair', _hairController),

            const SizedBox(height: 32),

            // Portfolio Images Section
            _sectionTitle('Portfolio Images'),
            const SizedBox(height: 12),
            if (_portfolioImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _portfolioImages.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(_portfolioImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.white, width: 1),
                            ),
                            child: const Icon(LucideIcons.x, size: 14, color: AppTheme.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _actionButton(
              icon: LucideIcons.imagePlus,
              label: 'Add Photos',
              onTap: _isSaving ? null : _addImages,
            ),

            const SizedBox(height: 24),

            // Video Section
            _sectionTitle('Portfolio Video'),
            const SizedBox(height: 12),
            if (_portfolioVideo != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0DCD5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.video, color: AppTheme.black),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Video uploaded', style: GoogleFonts.montserrat(color: AppTheme.black)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _portfolioVideo = null),
                      child: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                    ),
                  ],
                ),
              ),
            if (_portfolioVideo == null)
              _actionButton(
                icon: LucideIcons.video,
                label: 'Add Video',
                onTap: _isSaving ? null : _addVideo,
              ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.black,
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller, {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.montserrat(color: AppTheme.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(color: AppTheme.grey),
          filled: true,
          fillColor: AppTheme.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0DCD5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0DCD5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.black),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0DCD5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onTap == null ? AppTheme.grey : AppTheme.black),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: onTap == null ? AppTheme.grey : AppTheme.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
