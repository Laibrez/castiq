import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/services/media_upload_service.dart';

class EditBrandProfileScreen extends StatefulWidget {
  final UserModel userData;

  const EditBrandProfileScreen({super.key, required this.userData});

  @override
  State<EditBrandProfileScreen> createState() => _EditBrandProfileScreenState();
}

class _EditBrandProfileScreenState extends State<EditBrandProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final MediaUploadService _uploadService = MediaUploadService();
  final AuthService _authService = AuthService();

  // Text Controllers
  late TextEditingController _companyNameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;

  // State
  bool _isSaving = false;
  String _saveStatus = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.userData.companyName ?? widget.userData.name);
    _bioController = TextEditingController(text: widget.userData.bio ?? '');
    _locationController = TextEditingController(text: widget.userData.location ?? '');
    _websiteController = TextEditingController(text: widget.userData.website ?? '');
    
    _profileImageUrl = widget.userData.profileImageUrl;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
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
      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'companyName': _companyNameController.text,
        'name': _companyNameController.text, // Keep name in sync for now
        'bio': _bioController.text,
        'location': _locationController.text,
        'website': _websiteController.text,
        'profileImageUrl': _profileImageUrl,
      });

      setState(() {
        _isSaving = false;
        _saveStatus = 'Changes saved successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
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

  Future<void> _changeProfileImage() async {
    final image = await _uploadService.pickImage();
    if (image == null) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isSaving = true;
      _saveStatus = 'Uploading logo...';
    });

    final url = await _uploadService.uploadSingleImage(
      userId: userId,
      imageFile: image,
      folder: 'profiles',
      onProgress: (progress) {
        setState(() => _saveStatus = 'Uploading logo... ${(progress * 100).toInt()}%');
      },
    );

    if (url != null) {
      setState(() {
        _profileImageUrl = url;
        _isSaving = false;
        _saveStatus = 'Logo updated!';
      });
    } else {
      setState(() {
        _isSaving = false;
        _saveStatus = 'Failed to upload logo';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Brand Profile',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF818CF8)),
                  )
                : const Text('Save', style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
          ),
        ],
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
                  color: _saveStatus.contains('success') || _saveStatus.contains('updated')
                      ? Colors.green.withOpacity(0.1)
                      : const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (_isSaving)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF818CF8)),
                      )
                    else
                      Icon(
                        _saveStatus.contains('Failed') ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
                        color: _saveStatus.contains('Failed') ? Colors.red : Colors.green,
                        size: 18,
                      ),
                    const SizedBox(width: 12),
                    Text(_saveStatus, style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                      color: Colors.white.withOpacity(0.1),
                      image: _profileImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_profileImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImageUrl == null
                        ? const Icon(LucideIcons.image, size: 40, color: Colors.white54)
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
                          color: const Color(0xFF818CF8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Basic Info Section
            _sectionTitle('Brand Information'),
            _textField('Company Name', _companyNameController, validator: (v) => v!.isEmpty ? 'Required' : null),
            _textField('Location', _locationController),
            _textField('Website', _websiteController),
            _textField('Bio', _bioController, maxLines: 4),

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
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1)),
          ),
        ),
      ),
    );
  }
}
