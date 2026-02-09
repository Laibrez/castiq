import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_application_1/features/dashboard/dashboard_screen.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class IdVerificationScreen extends StatefulWidget {
  final String userType;

  const IdVerificationScreen({super.key, required this.userType});

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  bool _idUploaded = false;
  bool _selfieUploaded = false;
  bool _isLoading = false;
  String? _idDocumentUrl;
  String? _selfieUrl;
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final String fileName = path.basename(image.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String userId = _authService.currentUser?.uid ?? 'temp_user_id';
      
      final cloudinary = CloudinaryPublic('dhkugnymi', 'castiq', cache: false);
      CloudinaryResponse response;
      if (kIsWeb) {
         final bytes = await image.readAsBytes();
         response = await cloudinary.uploadFile(
           CloudinaryFile.fromBytesData(
             bytes,
             identifier: '${type}_$timestamp',
             folder: 'model_verification/$userId',
           ),
         );
      } else {
         response = await cloudinary.uploadFile(
           CloudinaryFile.fromFile(
             image.path, 
             identifier: '${type}_$timestamp',
             folder: 'model_verification/$userId',
           ),
         );
      }
      
      final String downloadUrl = response.secureUrl;

      setState(() {
        _isLoading = false;
        if (type == 'id') {
          _idDocumentUrl = downloadUrl;
          _idUploaded = true;
        } else {
          _selfieUrl = downloadUrl;
          _selfieUploaded = true;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_idUploaded || !_selfieUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both ID and selfie')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw 'User not found';

      Map<String, dynamic> updateData = {
        'isVerified': true,
        'idDocumentUrl': _idDocumentUrl,
        'selfieUrl': _selfieUrl,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (!mounted) return;
      if (!mounted) return;
      // Navigate back to root (AuthWrapper)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit verification: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 3 of 10',
                style: GoogleFonts.montserrat(
                  color: AppTheme.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 3 / 10,
                  backgroundColor: AppTheme.black.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 120,
        title: Text(
          'Verify Identity',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.w700,
            color: AppTheme.black,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0DCD5)),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Verify Your Identity',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload your ID and a selfie to verify you are who you say you are',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 32),
                // Two side-by-side upload sections
                Row(
                  children: [
                    Expanded(
                      child: _UploadSection(
                        title: 'Government ID',
                        icon: Icons.credit_card,
                        buttonText: 'Upload ID',
                        description: 'Passport, Driver\'s License, or National ID',
                        isUploaded: _idUploaded,
                        onTap: () => _pickAndUploadImage('id'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _UploadSection(
                        title: 'Selfie with ID',
                        icon: Icons.camera_alt,
                        buttonText: 'Upload Selfie',
                        description: 'Hold your ID next to your face',
                        isUploaded: _selfieUploaded,
                        onTap: () => _pickAndUploadImage('selfie'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Informational box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0DCD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why do we need this?',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Identity verification helps keep our community safe and ensures brands can trust the models they work with.',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppTheme.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_idUploaded && _selfieUploaded && !_isLoading)
                        ? _handleSubmit
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.black,
                      disabledBackgroundColor: AppTheme.black.withOpacity(0.05),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.black),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

class _UploadSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String buttonText;
  final String description;
  final bool isUploaded;
  final VoidCallback onTap;

  const _UploadSection({
    required this.title,
    required this.icon,
    required this.buttonText,
    required this.description,
    required this.isUploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isUploaded ? Colors.green : const Color(0xFFE0DCD5),
            width: isUploaded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.white,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppTheme.grey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUploaded ? Colors.green : AppTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUploaded ? 'Uploaded' : buttonText,
                style: GoogleFonts.montserrat(
                  color: isUploaded ? Colors.white : AppTheme.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: AppTheme.grey,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
