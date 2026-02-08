import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cloudinary_public/cloudinary_public.dart'; // From Stash
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/features/auth/registration_success_screen.dart';
import 'package:flutter_application_1/features/auth/widgets/z_card_widget.dart'; // From Stash
import 'package:google_fonts/google_fonts.dart'; // From Stash
import 'package:flutter_application_1/core/services/auth_service.dart'; // From Upstream

class ModelRegistrationFlow extends StatefulWidget {
  const ModelRegistrationFlow({super.key});

  @override
  State<ModelRegistrationFlow> createState() => _ModelRegistrationFlowState();
}

class _ModelRegistrationFlowState extends State<ModelRegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 9; // merged Account, Identity, Interests, Photo, Portfolio, Measurements, Location, Social, Summary

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // Added missing controller
  
  // Measurements
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _bustController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipsController = TextEditingController();
  final TextEditingController _shoeController = TextEditingController();

  // Location
  final TextEditingController _locationController = TextEditingController();
  bool _willingToTravel = false;

  // Interests
  final List<String> _selectedInterests = [];
  
  // Identity Verification state (Upstream)
  String? _idDocumentUrl;
  String? _selfieUrl;
  final AuthService _authService = AuthService(); // Upstream
  final ImagePicker _picker = ImagePicker(); // Upstream
  bool _isUploadingId = false;
  bool _isUploadingSelfie = false;

  // Portfolio / Profile State (Stash)
  File? _selectedImageFile; // Legacy
  Uint8List? _selectedImageBytes;
  final List<Uint8List> _portfolioImages = [];
  List<int> _zCardSelectedIndices = [0, 1, 2, 3]; // Default to first 4
  
  // Social Media
  List<Map<String, String>> _socialMediaLinks = [];

  bool _isSubmitting = false;

  // --- Identity Verification Methods (Upstream) ---

  Future<void> _uploadId(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingId = true);

      final String fileName = path.basename(image.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      final cloudinary = CloudinaryPublic('dhkugnymi', 'castiq', cache: false);
      CloudinaryResponse response;
      if (kIsWeb) {
         final bytes = await image.readAsBytes();
         response = await cloudinary.uploadFile(
           CloudinaryFile.fromBytesData(
             bytes,
             identifier: 'id_$timestamp',
             folder: 'model_verification/$userId',
           ),
         );
      } else {
         response = await cloudinary.uploadFile(
           CloudinaryFile.fromFile(
             image.path, 
             identifier: 'id_$timestamp',
             folder: 'model_verification/$userId',
           ),
         );
      }

      setState(() {
        _idDocumentUrl = response.secureUrl;
        _isUploadingId = false;
      });
    } catch (e) {
      setState(() => _isUploadingId = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading ID: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingSelfie = true);

      final String fileName = path.basename(image.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      final cloudinary = CloudinaryPublic('dhkugnymi', 'castiq', cache: false);
      CloudinaryResponse response;
      if (kIsWeb) {
         final bytes = await image.readAsBytes();
         response = await cloudinary.uploadFile(
           CloudinaryFile.fromBytesData(
             bytes,
             identifier: 'selfie_$timestamp',
             folder: 'model_verification/$userId',
           ),
         );
      } else {
         response = await cloudinary.uploadFile(
           CloudinaryFile.fromFile(
             image.path, 
             identifier: 'selfie_$timestamp',
             folder: 'model_verification/$userId',
           ),
         );
      }

      setState(() {
        _selfieUrl = response.secureUrl;
        _isUploadingSelfie = false;
      });
    } catch (e) {
      setState(() => _isUploadingSelfie = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading selfie: ${e.toString()}')),
        );
      }
    }
  }

  void _showIdSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.black),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _uploadId(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.black),
                title: const Text('Take a Photo', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _uploadId(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Portfolio / Profile Methods (Stash) ---

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final length = await image.length();
        if (length > 5 * 1024 * 1024) { // 5MB limit
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Image too large. Max 5MB allowed.')),
             );
           }
           return;
        }

        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      // Silent error
    }
  }

  Future<void> _pickPortfolioImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (var i in images) {
          final length = await i.length();
          if (length > 5 * 1024 * 1024) {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Skipped ${i.name}: File too large (Max 5MB)')),
               );
             }
             continue;
          }
          final bytes = await i.readAsBytes();
          setState(() {
            _portfolioImages.add(bytes);
          });
        }
      }
    } catch (e) {
      // Silent error
    }
  }

  // --- Submit Registration (Merged) ---

  Future<void> _submitRegistration() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a profile photo')),
        );
        return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creating user...'), duration: Duration(milliseconds: 500)));
      
      // 1. Create User
      User? user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
         final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
           email: _emailController.text.trim(),
           password: _passwordController.text.trim(),
         );
         user = userCredential.user;
      }
      
      if (user == null) throw Exception('Failed to create or get user');

      // 2. Upload Profile to Cloudinary
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading profile image...'), duration: Duration(milliseconds: 500)));
      
      String? downloadUrl;
      final cloudinary = CloudinaryPublic('dhkugnymi', 'castiq', cache: false);
      
      if (_selectedImageBytes != null) {
         try {
           final timestamp = DateTime.now().millisecondsSinceEpoch;
           CloudinaryResponse response = await cloudinary.uploadFile(
             CloudinaryFile.fromBytesData(
               _selectedImageBytes!,
               identifier: '${user.uid}_profile_$timestamp', // Unique identifier to prevent caching
               folder: 'profiles',
             ),
           );
           downloadUrl = response.secureUrl;
         } catch (e) {
           print("Profile upload failed: $e");
           // Fallback to default avatar if upload fails
           downloadUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000&auto=format&fit=crop';
         }
      } else {
         // No image selected (though validation should prevent this), use fallback
         downloadUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000&auto=format&fit=crop';
      }

      // 3. Upload Portfolio to Cloudinary
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading portfolio...'), duration: Duration(milliseconds: 500)));
      List<String> portfolioUrls = [];
      for (int i = 0; i < _portfolioImages.length; i++) {
          try {
             final timestamp = DateTime.now().millisecondsSinceEpoch;
             CloudinaryResponse response = await cloudinary.uploadFile(
               CloudinaryFile.fromBytesData(
                 _portfolioImages[i],
                 identifier: 'portfolio_${user.uid}_${timestamp}_$i',
                 folder: 'portfolio_images',
               ),
             );
             portfolioUrls.add(response.secureUrl);
          } catch (e) {
             print('Error uploading portfolio image $i: $e');
          }
      }

      // 4. Save to Firestore (Merged Data)
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving profile...'), duration: Duration(milliseconds: 500)));
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': 'model',
        'profileImageUrl': downloadUrl,
        'portfolio': portfolioUrls,
        'zCard': {
           'images': _zCardSelectedIndices.map((i) => i < portfolioUrls.length ? portfolioUrls[i] : null).whereType<String>().toList(),
           'generatedAt': FieldValue.serverTimestamp(),
        },
        'verification': {
          'idDocumentUrl': _idDocumentUrl,
          'selfieUrl': _selfieUrl,
          'verified': false,
          'submittedAt': FieldValue.serverTimestamp(),
        },
        'interests': _selectedInterests,
        'measurements': {
          'height': _heightController.text,
          'bust': _bustController.text,
          'waist': _waistController.text,
          'hips': _hipsController.text,
          'shoe': _shoeController.text,
        },
        'location': _locationController.text,
        'willingToTravel': _willingToTravel,
        'socialMedia': _socialMediaLinks,
        'approved': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrationSuccessScreen(
                message: 'Application Sent! We will review your profile.',
              ),
            ),
          );
      }

    } catch (e) {
       print("Registration Error: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
         );
       }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: _previousStep,
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            minHeight: 6,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (int page) {
          setState(() {
            _currentStep = page;
          });
        },
        children: [
          _Step1Account(
            nextStep: _nextStep,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
          ),
          _Step2IdentityVerification(
             nextStep: _nextStep, 
             onIdUploaded: (url) => setState(() => _idDocumentUrl = url), 
             onSelfieUploaded: (url) => setState(() => _selfieUrl = url), 
             idDocumentUrl: _idDocumentUrl, 
             selfieUrl: _selfieUrl, 
             isUploadingId: _isUploadingId,
             isUploadingSelfie: _isUploadingSelfie,
             onUploadId: _showIdSourceDialog,
             onTakeSelfie: _takeSelfie,
          ),
          _Step3Interests(
            nextStep: _nextStep,
            selectedInterests: _selectedInterests,
          ),
          _Step4ProfilePhoto(
            nextStep: _nextStep, 
            pickImage: _pickImage,
            imageBytes: _selectedImageBytes,
          ),
           _Step5Portfolio(
             nextStep: _nextStep,
             pickImages: _pickPortfolioImages,
             images: _portfolioImages,
             onRemove: (index) => setState(() => _portfolioImages.removeAt(index)),
          ),
          _Step6Measurements(
            nextStep: _nextStep,
            heightController: _heightController,
            bustController: _bustController,
            waistController: _waistController,
            hipsController: _hipsController,
            shoeController: _shoeController,
          ),
          _Step7Location(
            nextStep: _nextStep,
            locationController: _locationController,
            onTravelChanged: (val) => setState(() => _willingToTravel = val),
            willingToTravel: _willingToTravel,
          ),
          _StepSocialMedia(
            nextStep: _nextStep, 
            socialLinks: _socialMediaLinks, 
            onLinksChanged: (links) => setState(() => _socialMediaLinks = links),
          ),
            _Step9Summary(
            onSubmit: _submitRegistration,
            isLoading: _isSubmitting,
            email: _emailController.text,
            name: 'Model Applicant', 
            location: _locationController.text,
            interests: _selectedInterests,
            profileImage: _selectedImageBytes,
            allPortfolioImages: _portfolioImages,
            socialLinks: _socialMediaLinks,
            stats: {
                'Height': _heightController.text,
                'Bust': _bustController.text,
                'Waist': _waistController.text,
                'Hips': _hipsController.text,
                'Shoe': _shoeController.text,
            },
            onZCardImagesUpdated: (images) {
              final newIndices = <int>[];
              for (var img in images) {
                final index = _portfolioImages.indexOf(img as Uint8List);
                if (index != -1) newIndices.add(index);
              }
              setState(() => _zCardSelectedIndices = newIndices);
            },
          ),
        ],
      ),
    );
  }
}

// --- Step Widgets ---

class _Step1Account extends StatelessWidget {
  final VoidCallback nextStep;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const _Step1Account({
    required this.nextStep,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 1', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          _buildTextField('Email', Icons.email_outlined, controller: emailController),
          const SizedBox(height: 16),
          _buildTextField('Password', Icons.lock_outline, obscureText: true, controller: passwordController),
          const SizedBox(height: 16),
          _buildTextField('Confirm Password', Icons.lock_outline, obscureText: true, controller: confirmPasswordController),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool obscureText = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Step2IdentityVerification extends StatelessWidget {
  final VoidCallback nextStep;
  final Function(String?) onIdUploaded;
  final Function(String?) onSelfieUploaded;
  final String? idDocumentUrl;
  final String? selfieUrl;
  final bool isUploadingId;
  final bool isUploadingSelfie;
  final VoidCallback onUploadId;
  final VoidCallback onTakeSelfie;

  const _Step2IdentityVerification({
    required this.nextStep,
    required this.onIdUploaded,
    required this.onSelfieUploaded,
    required this.idDocumentUrl,
    required this.selfieUrl,
    required this.isUploadingId,
    required this.isUploadingSelfie,
    required this.onUploadId,
    required this.onTakeSelfie,
  });

  @override
  Widget build(BuildContext context) {
    final bool canProceed = idDocumentUrl != null && selfieUrl != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 2', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('Verify Your Identity', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Upload your ID and a selfie to verify you are who you say you are', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _IdentityUploadSection(
                  title: 'Government ID',
                  icon: Icons.credit_card,
                  buttonText: 'Upload ID',
                  description: 'Passport, Driver\'s License, or National ID',
                  isUploaded: idDocumentUrl != null,
                  isUploading: isUploadingId,
                  onTap: onUploadId,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _IdentityUploadSection(
                  title: 'Selfie with ID',
                  icon: Icons.camera_alt,
                  buttonText: 'Take Selfie',
                  description: 'Hold your ID next to your face',
                  isUploaded: selfieUrl != null,
                  isUploading: isUploadingSelfie,
                  onTap: onTakeSelfie,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(12)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Why do we need this?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 8),
                Text('Identity verification helps keep our community safe and ensures brands can trust the models they work with.', style: TextStyle(fontSize: 14, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canProceed ? nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                disabledBackgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityUploadSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String buttonText;
  final String description;
  final bool isUploaded;
  final bool isUploading;
  final VoidCallback onTap;

  const _IdentityUploadSection({
    required this.title, required this.icon, required this.buttonText, required this.description,
    required this.isUploaded, required this.isUploading, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: isUploaded ? Colors.green : Colors.white24, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 16),
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: isUploading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Icon(icon, size: 40, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: isUploaded ? Colors.green : Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Text(isUploaded ? 'Uploaded' : buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _Step3Interests extends StatefulWidget {
  final VoidCallback nextStep;
  final List<String> selectedInterests;
  const _Step3Interests({required this.nextStep, required this.selectedInterests});

  @override
  State<_Step3Interests> createState() => _Step3InterestsState();
}

class _Step3InterestsState extends State<_Step3Interests> {
  final List<String> categories = ['Fashion', 'Commercial', 'Beauty', 'Editorial', 'Runway', 'Lifestyle', 'Fitness', 'Parts'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What are your interests?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories.map((cat) {
              final isSelected = widget.selectedInterests.contains(cat);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      widget.selectedInterests.remove(cat);
                    } else {
                      widget.selectedInterests.add(cat);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.white10),
                  ),
                  child: Text(cat, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: widget.nextStep, child: const Text('Next'))),
        ],
      ),
    );
  }
}

class _Step4ProfilePhoto extends StatelessWidget {
  final VoidCallback nextStep;
  final VoidCallback pickImage;
  final Uint8List? imageBytes;

  const _Step4ProfilePhoto({required this.nextStep, required this.pickImage, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload your profile picture', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('1 required photo', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 48),
          Center(
            child: GestureDetector(
              onTap: pickImage,
              child: Column(
                children: [
                  Container(
                    height: 200, width: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white10, style: BorderStyle.solid),
                      image: imageBytes != null ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover) : null,
                    ),
                    child: imageBytes == null ? const Icon(LucideIcons.camera, size: 48, color: Colors.white24) : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Select file from your device', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: nextStep, child: const Text('Next'))),
        ],
      ),
    );
  }
}

class _Step5Portfolio extends StatelessWidget {
  final VoidCallback nextStep;
  final VoidCallback pickImages;
  final List<Uint8List> images;
  final ValueChanged<int> onRemove;

  const _Step5Portfolio({required this.nextStep, required this.pickImages, required this.images, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Build your portfolio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Upload 4 photos (required) and 1 video (optional)', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          Text('UPLOAD FILES', style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
               ...images.asMap().entries.map((entry) {
                 final index = entry.key; final bytes = entry.value;
                 return Stack(
                   clipBehavior: Clip.none,
                   children: [
                     Container(
                       width: 100, height: 100,
                       decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)),
                     ),
                     Positioned(
                       top: -8, right: -8,
                       child: GestureDetector(
                         onTap: () => onRemove(index),
                         child: Container(
                           padding: const EdgeInsets.all(4),
                           decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                           child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                         ),
                       ),
                     ),
                   ],
                 );
               }),
               GestureDetector(
                onTap: pickImages,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.plus, color: Colors.white24, size: 28), SizedBox(height: 4), Text('Add', style: TextStyle(color: Colors.white24, fontSize: 10))]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: nextStep, child: const Text('Next'))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Step6Measurements extends StatelessWidget {
  final VoidCallback nextStep;
  final TextEditingController heightController;
  final TextEditingController bustController;
  final TextEditingController waistController;
  final TextEditingController hipsController;
  final TextEditingController shoeController;

  const _Step6Measurements({
    required this.nextStep, required this.heightController, required this.bustController,
    required this.waistController, required this.hipsController, required this.shoeController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your measurements', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          _buildMeasureField('Height (cm)', heightController),
          const SizedBox(height: 16),
          _buildMeasureField('Chest / Bust (cm)', bustController),
          const SizedBox(height: 16),
          _buildMeasureField('Waist (cm)', waistController),
          const SizedBox(height: 16),
          _buildMeasureField('Hips (cm)', hipsController),
          const SizedBox(height: 16),
          _buildMeasureField('Shoe size', shoeController),
          const SizedBox(height: 48),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: nextStep, child: const Text('Next'))),
        ],
      ),
    );
  }

  Widget _buildMeasureField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }
}

class _Step7Location extends StatelessWidget {
  final VoidCallback nextStep;
  final TextEditingController locationController;
  final ValueChanged<bool> onTravelChanged;
  final bool willingToTravel;

  const _Step7Location({required this.nextStep, required this.locationController, required this.onTravelChanged, required this.willingToTravel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Where are you based?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          _buildLocationField('Base city / country', LucideIcons.mapPin, locationController),
          const SizedBox(height: 32),
          const Text('Willing to travel?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildChoiceChip('Yes', true),
              const SizedBox(width: 12),
              _buildChoiceChip('No', false),
            ],
          ),
          const Spacer(),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: nextStep, child: const Text('Next'))),
        ],
      ),
    );
  }

  Widget _buildLocationField(String label, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.white54), filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }

  Widget _buildChoiceChip(String label, bool value) {
    final isSelected = willingToTravel == value;
    return GestureDetector(
      onTap: () => onTravelChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _StepSocialMedia extends StatefulWidget {
  final VoidCallback nextStep;
  final List<Map<String, String>> socialLinks;
  final ValueChanged<List<Map<String, String>>> onLinksChanged;

  const _StepSocialMedia({required this.nextStep, required this.socialLinks, required this.onLinksChanged});

  @override
  State<_StepSocialMedia> createState() => _StepSocialMediaState();
}

class _StepSocialMediaState extends State<_StepSocialMedia> {
  final TextEditingController _usernameController = TextEditingController();
  String _selectedPlatform = 'Instagram';
  final List<String> _platforms = ['Instagram', 'Facebook', 'TikTok', 'LinkedIn', 'YouTube', 'Twitter', 'Other'];

  void _addLink() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;
    String url = username;
    final newLinks = List<Map<String, String>>.from(widget.socialLinks);
    newLinks.add({'platform': _selectedPlatform, 'url': url});
    widget.onLinksChanged(newLinks);
    _usernameController.clear();
  }

  void _removeLink(int index) {
    final newLinks = List<Map<String, String>>.from(widget.socialLinks);
    newLinks.removeAt(index);
    widget.onLinksChanged(newLinks);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Online Influence', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Share your social media profiles', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPlatform,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPlatform = val!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'Username / Link', hintStyle: const TextStyle(color: Colors.white24), filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _addLink, icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF6366F1))),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.socialLinks.isNotEmpty)
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: widget.socialLinks.asMap().entries.map((entry) {
                  final index = entry.key; final item = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(item['platform']!, style: const TextStyle(color: Colors.white70)),
                    subtitle: Text(item['url']!, style: const TextStyle(color: Colors.white30), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(icon: const Icon(LucideIcons.trash2, color: Colors.white24, size: 18), onPressed: () => _removeLink(index)),
                  );
                }).toList(),
              ),
            ),
          const Spacer(),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: widget.nextStep, child: const Text('Next'))),
        ],
      ),
    );
  }
}

class _Step9Summary extends StatelessWidget {
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? email;
  final String name;
  final String location;
  final List<String> interests;
  final Uint8List? profileImage;
  final List<Uint8List> allPortfolioImages;
  final Map<String, String> stats;
  final List<Map<String, String>> socialLinks;
  final ValueChanged<List<dynamic>> onZCardImagesUpdated;

  const _Step9Summary({
    required this.onSubmit, required this.isLoading, this.email, required this.name,
    required this.location, required this.interests, this.profileImage, required this.allPortfolioImages,
    required this.stats, required this.socialLinks, required this.onZCardImagesUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review Information', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Review your automatic Z-Card and standard details.', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          
          const Text('YOUR Z-CARD', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ZCardWidget(
            allImages: allPortfolioImages,
            name: name,
            category: interests.isNotEmpty ? interests.first : 'Model',
            location: location,
            willingToTravel: true,
            stats: stats,
            onZCardImagesChanged: onZCardImagesUpdated,
          ),
          const SizedBox(height: 24),

          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[800],
              backgroundImage: profileImage != null ? MemoryImage(profileImage!) : null,
              child: profileImage == null ? const Icon(LucideIcons.user, size: 40, color: Colors.white54) : null,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSummarySection('Account', ['Email: $email', 'Location: $location']),
          _buildSummarySection('Measurements', stats.entries.map((e) => '${e.key}: ${e.value}').toList()),
          if (socialLinks.isNotEmpty) _buildSummarySection('Social Media', socialLinks.map((e) => '${e['platform']}: ${e['url']}').toList()),
          _buildSummarySection('Interests', [interests.join(', ')]),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('Confirm & Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(item, style: const TextStyle(color: Colors.white)))).toList(),
          ),
        ),
      ],
    );
  }
}
