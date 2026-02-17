import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/features/auth/registration_success_screen.dart';
import 'package:flutter_application_1/features/auth/widgets/z_card_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class ModelRegistrationFlow extends StatefulWidget {
  const ModelRegistrationFlow({super.key});

  @override
  State<ModelRegistrationFlow> createState() => _ModelRegistrationFlowState();
}

class _ModelRegistrationFlowState extends State<ModelRegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 8; // Account, Interests, Photo, Portfolio, Measurements, Location, Social, Summary

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
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
  
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  // Portfolio / Profile State
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final List<Uint8List> _portfolioImages = [];
  List<int> _zCardSelectedIndices = [0, 1, 2, 3];
  
  // Social Media
  List<Map<String, String>> _socialMediaLinks = [];

  bool _isSubmitting = false;

  // --- Portfolio / Profile Methods ---

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final length = await image.length();
        if (length > 5 * 1024 * 1024) {
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

  // --- Submit Registration ---

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
               identifier: '${user.uid}_profile_$timestamp',
               folder: 'profiles',
             ),
           );
           downloadUrl = response.secureUrl;
         } catch (e) {
           print("Profile upload failed: $e");
           downloadUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000&auto=format&fit=crop';
         }
      } else {
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

      // 4. Save to Firestore
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
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.black),
          onPressed: _previousStep,
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppTheme.grey.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
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

// ── Shared helpers ──

Widget _buildStyledTextField(String label, IconData icon, {
  bool obscureText = false,
  TextEditingController? controller,
  TextInputType? keyboardType,
}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
    keyboardType: keyboardType,
    style: GoogleFonts.montserrat(color: AppTheme.black),
      decoration: InputDecoration(
        labelText: label,
      labelStyle: GoogleFonts.montserrat(color: AppTheme.grey),
      prefixIcon: Icon(icon, color: AppTheme.grey, size: 20),
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
        borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
      ),
                ),
  );
}

Widget _buildStyledButton({required String label, required VoidCallback onPressed}) {
  return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
      onPressed: onPressed,
              style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.gold,
        foregroundColor: AppTheme.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
              ),
      child: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    );
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
          Text(
            'Create Account',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.black,
            ),
            ),
            const SizedBox(height: 8),
          Text(
            'Enter your credentials to get started.',
            style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey),
          ),
          const SizedBox(height: 32),
          _buildStyledTextField('Email', LucideIcons.mail, controller: emailController),
          const SizedBox(height: 16),
          _buildStyledTextField('Password', LucideIcons.lock, obscureText: true, controller: passwordController),
          const SizedBox(height: 16),
          _buildStyledTextField('Confirm Password', LucideIcons.lock, obscureText: true, controller: confirmPasswordController),
          const Spacer(),
          _buildStyledButton(label: 'Next', onPressed: nextStep),
        ],
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
          Text(
            'What are your interests?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the categories that match your style.',
            style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey),
          ),
          const SizedBox(height: 32),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.gold : AppTheme.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? AppTheme.gold : const Color(0xFFE0DCD5),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.montserrat(
                      color: isSelected ? AppTheme.black : AppTheme.grey,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          _buildStyledButton(label: 'Next', onPressed: widget.nextStep),
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
          Text(
            'Profile Picture',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1 required photo',
            style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey),
          ),
          const SizedBox(height: 48),
          Center(
            child: GestureDetector(
              onTap: pickImage,
              child: Column(
                children: [
                  Container(
                    height: 200, width: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFE0DCD5), width: 2),
                      image: imageBytes != null ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover) : null,
                    ),
                    child: imageBytes == null
                        ? Icon(LucideIcons.camera, size: 48, color: AppTheme.grey.withOpacity(0.4))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to select a photo',
                    style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _buildStyledButton(label: 'Next', onPressed: nextStep),
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
          Text(
            'Build Your Portfolio',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload 4 photos (required) and 1 video (optional)',
            style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey),
          ),
          const SizedBox(height: 32),
          Text(
            'UPLOAD FILES',
            style: GoogleFonts.montserrat(
              color: AppTheme.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
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
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: const Color(0xFFE0DCD5)),
                         image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
                       ),
                     ),
                     Positioned(
                       top: -8, right: -8,
                       child: GestureDetector(
                         onTap: () => onRemove(index),
                         child: Container(
                           padding: const EdgeInsets.all(4),
                           decoration: BoxDecoration(
                             color: Colors.red.shade400,
                             shape: BoxShape.circle,
                             border: Border.all(color: AppTheme.white, width: 1.5),
                           ),
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
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0DCD5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.plus, color: AppTheme.grey.withOpacity(0.4), size: 28),
                      const SizedBox(height: 4),
                      Text('Add', style: GoogleFonts.montserrat(color: AppTheme.grey.withOpacity(0.5), fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
          _buildStyledButton(label: 'Next', onPressed: nextStep),
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
          Text(
            'Your Measurements',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Industry-standard measurements.',
            style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey),
          ),
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
          _buildStyledButton(label: 'Next', onPressed: nextStep),
        ],
      ),
    );
  }

  Widget _buildMeasureField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
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
          borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
        ),
      ),
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
          Text(
            'Where Are You Based?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 32),
          _buildStyledTextField('Base city / country', LucideIcons.mapPin, controller: locationController),
          const SizedBox(height: 32),
          Text(
            'Willing to travel?',
            style: GoogleFonts.montserrat(
              color: AppTheme.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildChoiceChip('Yes', true),
              const SizedBox(width: 12),
              _buildChoiceChip('No', false),
            ],
          ),
          const Spacer(),
          _buildStyledButton(label: 'Next', onPressed: nextStep),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool value) {
    final isSelected = willingToTravel == value;
    return GestureDetector(
      onTap: () => onTravelChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.gold : AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.gold : const Color(0xFFE0DCD5),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isSelected ? AppTheme.black : AppTheme.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          Text(
            'Online Influence',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your social media profiles',
            style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0DCD5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPlatform,
                    dropdownColor: AppTheme.white,
                    style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: 14),
                    items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPlatform = val!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  style: GoogleFonts.montserrat(color: AppTheme.black),
                  decoration: InputDecoration(
                    hintText: 'Username / Link',
                    hintStyle: GoogleFonts.montserrat(color: AppTheme.grey.withOpacity(0.5)),
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
                      borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _addLink, icon: const Icon(LucideIcons.plusCircle, color: AppTheme.gold)),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.socialLinks.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DCD5)),
              ),
              child: Column(
                children: widget.socialLinks.asMap().entries.map((entry) {
                  final index = entry.key; final item = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(item['platform']!, style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.w500)),
                    subtitle: Text(item['url']!, style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(icon: Icon(LucideIcons.trash2, color: AppTheme.grey.withOpacity(0.5), size: 18), onPressed: () => _removeLink(index)),
                  );
                }).toList(),
              ),
            ),
          const Spacer(),
          _buildStyledButton(label: 'Next', onPressed: widget.nextStep),
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
          Text(
            'Review Information',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your automatic Z-Card and standard details.',
            style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey),
          ),
          const SizedBox(height: 32),
          
          Text(
            'YOUR Z-CARD',
            style: GoogleFonts.montserrat(
              color: AppTheme.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
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
              backgroundColor: AppTheme.lightGold.withOpacity(0.3),
              backgroundImage: profileImage != null ? MemoryImage(profileImage!) : null,
              child: profileImage == null
                  ? const Icon(LucideIcons.user, size: 40, color: AppTheme.grey)
                  : null,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.black,
                disabledBackgroundColor: AppTheme.grey.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.black)) 
                  : Text('Confirm & Submit', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15)),
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
        Text(
          title.toUpperCase(),
          style: GoogleFonts.montserrat(
            color: AppTheme.gold,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0DCD5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item, style: GoogleFonts.montserrat(color: AppTheme.black, fontSize: 14)),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
