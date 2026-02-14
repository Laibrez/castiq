import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/auth/registration_success_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:country_picker/country_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class BrandRegistrationFlow extends StatefulWidget {
  const BrandRegistrationFlow({super.key});

  @override
  State<BrandRegistrationFlow> createState() => _BrandRegistrationFlowState();
}

class _BrandRegistrationFlowState extends State<BrandRegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7;
  bool _isSubmitting = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressCountryController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _websiteController = TextEditingController();

  final _phoneNumberController = TextEditingController();
  List<Map<String, String>> _socialMediaLinks = [];

  final _repNameController = TextEditingController();
  final _repRoleController = TextEditingController();
  final _repEmailController = TextEditingController();

  // Document Upload State
  PlatformFile? _proofOfAddressFile;

  Future<void> _pickProofOfAddress() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File too large. Max 5MB allowed.')),
            );
          }
          return;
        }

        setState(() {
          _proofOfAddressFile = file;
        });
      }
    } catch (e) {
      // Silent error
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);
    
    try {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting submission...'), duration: Duration(milliseconds: 500)));
      
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creating account...'), duration: Duration(milliseconds: 500)));
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          user = userCredential.user;
      }
      
      if (user == null) throw Exception("Failed to create user");

      String? proofUrl;
      if (_proofOfAddressFile != null) {
          final ext = _proofOfAddressFile!.extension ?? 'jpg';
          final cloudinary = CloudinaryPublic('dhkugnymi', 'castiq', cache: false);
          
          print('Uploading proof of address to Cloudinary...');
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading documents...'), duration: Duration(milliseconds: 500)));
          
          try {
             CloudinaryResponse response;
             if (_proofOfAddressFile!.bytes != null) {
                 response = await cloudinary.uploadFile(
                   CloudinaryFile.fromBytesData(
                     _proofOfAddressFile!.bytes!,
                     identifier: 'proof_${user.uid}',
                     folder: 'business_docs/${user.uid}',
                     resourceType: CloudinaryResourceType.Auto, 
                   ),
                 );
             } else if (_proofOfAddressFile!.path != null) {
                 response = await cloudinary.uploadFile(
                   CloudinaryFile.fromFile(
                     _proofOfAddressFile!.path!,
                     identifier: 'proof_${user.uid}',
                     folder: 'business_docs/${user.uid}',
                     resourceType: CloudinaryResourceType.Auto,
                   ),
                 );
             } else {
                 throw Exception('No file data available');
             }
             proofUrl = response.secureUrl;
             print('Upload successful: $proofUrl');
          } catch (e) {
             print('Proof upload failed: $e');
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Proof upload failed: $e')));
          }
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving profile data...'), duration: Duration(milliseconds: 500)));
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': 'brand',
        'companyName': _businessNameController.text.trim(),
        'country': _countryController.text.trim(),
        'registrationNumber': _regNumberController.text.trim(),
        'address': {
          'street': _addressController.text.trim(),
          'country': _addressCountryController.text.trim(),
        },
        'proofOfAddressUrl': proofUrl,
        'taxId': _taxIdController.text.trim(),
        'phone': _phoneNumberController.text.trim(),
        'website': _websiteController.text.trim(),
        'socialMedia': _socialMediaLinks,
        'representative': {
          'name': _repNameController.text.trim(),
          'role': _repRoleController.text.trim(),
          'email': _repEmailController.text.trim(),
        },
        'approved': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegistrationSuccessScreen(
              message: 'Application Sent!',
            ),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      String message = 'Registration Failed';
      if (e.code == 'network-request-failed' || e.code == 'unavailable') {
        message = 'No internet connection. Please check your network and try again.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please check your connection.'), backgroundColor: Colors.red),
        );
        print('Registration Generic Error: $e');
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
          _Step1BusinessAccount(
            nextStep: _nextStep,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
          ),
          _Step2BusinessInfo(
            nextStep: _nextStep,
            nameController: _businessNameController,
            countryController: _countryController,
            regNumController: _regNumberController,
            phoneController: _phoneNumberController,
          ),
          _Step3BusinessAddress(
            nextStep: _nextStep,
            addressController: _addressController,
            countryController: _addressCountryController,
            pickFile: _pickProofOfAddress,
            pickedFile: _proofOfAddressFile,
          ),
          _Step4TaxInfo(
            nextStep: _nextStep,
            taxIdController: _taxIdController,
          ),
          _Step5OnlinePresence(
            nextStep: _nextStep,
            websiteController: _websiteController,
            socialLinks: _socialMediaLinks,
            onLinksChanged: (links) => setState(() => _socialMediaLinks = links),
          ),
          _Step6AuthorizedRep(
            nextStep: _nextStep,
            nameController: _repNameController,
            roleController: _repRoleController,
            emailController: _repEmailController,
          ),
          _Step7Summary(
            onSubmit: _submitRegistration,
            isLoading: _isSubmitting,
            businessName: _businessNameController.text,
            email: _emailController.text,
            country: _countryController.text,
            address: '${_addressController.text}, ${_addressCountryController.text}',
            taxId: _taxIdController.text,
            phone: _phoneNumberController.text,
            repName: _repNameController.text,
            socialLinks: _socialMediaLinks,
            proofFile: _proofOfAddressFile,
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ──

Widget _buildBrandTextField(String label, IconData icon, TextEditingController controller, {
  bool obscureText = false,
  String? Function(String?)? validator,
  bool readOnly = false,
  VoidCallback? onTap,
  Widget? suffixIcon,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    readOnly: readOnly,
    onTap: onTap,
    validator: validator ?? (v) => v == null || v.isEmpty ? 'Required' : null,
    style: GoogleFonts.montserrat(color: AppTheme.black),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(color: AppTheme.grey),
      prefixIcon: Icon(icon, color: AppTheme.grey, size: 20),
      suffixIcon: suffixIcon,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
    ),
  );
}

Widget _buildBrandButton({required String label, required VoidCallback onPressed}) {
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

class _Step1BusinessAccount extends StatefulWidget {
  final VoidCallback nextStep;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const _Step1BusinessAccount({
    required this.nextStep,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<_Step1BusinessAccount> createState() => _Step1BusinessAccountState();
}

class _Step1BusinessAccountState extends State<_Step1BusinessAccount> {
  final _formKey = GlobalKey<FormState>();

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      widget.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
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
              'Set up your business credentials.',
              style: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey),
            ),
            const SizedBox(height: 32),
            _buildBrandTextField(
              'Business Email', 
              LucideIcons.mail, 
              widget.emailController,
              validator: (v) => v == null || v.isEmpty ? 'Email required' : null,
            ),
            const SizedBox(height: 16),
            _buildBrandTextField(
              'Password', 
              LucideIcons.lock, 
              widget.passwordController, 
              obscureText: true,
              validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 16),
            _buildBrandTextField(
              'Confirm Password', 
              LucideIcons.lock, 
              widget.confirmPasswordController, 
              obscureText: true,
              validator: (v) {
                if(v == null || v.isEmpty) return 'Confirm password';
                if(v != widget.passwordController.text) return 'Passwords mismatch';
                return null;
              },
            ),
            const Spacer(),
            _buildBrandButton(label: 'Next', onPressed: _validateAndContinue),
          ],
        ),
      ),
    );
  }
}

class _Step2BusinessInfo extends StatefulWidget {
  final VoidCallback nextStep;
  final TextEditingController nameController;
  final TextEditingController countryController;
  final TextEditingController regNumController;
  final TextEditingController phoneController;

  const _Step2BusinessInfo({
    required this.nextStep,
    required this.nameController,
    required this.countryController,
    required this.regNumController,
    required this.phoneController,
  });

  @override
  State<_Step2BusinessInfo> createState() => _Step2BusinessInfoState();
}

class _Step2BusinessInfoState extends State<_Step2BusinessInfo> {
  final _formKey = GlobalKey<FormState>();

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      widget.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 32),
            _buildBrandTextField('Business Name', LucideIcons.building, widget.nameController),
            const SizedBox(height: 16),
            _buildCountryField(context, widget.countryController),
            const SizedBox(height: 16),
            _buildBrandTextField('Business Registration Number', LucideIcons.fileText, widget.regNumController),
            const SizedBox(height: 16),
            _buildBrandTextField('Phone Number', LucideIcons.phone, widget.phoneController),
            const Spacer(),
            _buildBrandButton(label: 'Next', onPressed: _validateAndContinue),
          ],
        ),
      ),
    );
  }
}

Widget _buildCountryField(BuildContext context, TextEditingController controller) {
  return _buildBrandTextField(
    'Country',
    LucideIcons.globe,
    controller,
      readOnly: true,
    suffixIcon: const Icon(LucideIcons.chevronDown, color: AppTheme.grey, size: 20),
      onTap: () {
        showCountryPicker(
          context: context,
          countryListTheme: CountryListThemeData(
            flagSize: 25,
          backgroundColor: AppTheme.white,
          textStyle: GoogleFonts.montserrat(fontSize: 16, color: AppTheme.black),
            bottomSheetHeight: 500,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            inputDecoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Start typing to search',
            prefixIcon: const Icon(LucideIcons.search, color: AppTheme.grey),
              border: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.grey.withOpacity(0.2)),
              ),
            labelStyle: GoogleFonts.montserrat(color: AppTheme.grey),
            hintStyle: GoogleFonts.montserrat(color: AppTheme.grey),
            ),
          ),
          onSelect: (Country country) {
              controller.text = country.name;
          },
        );
      },
  );
}

class _Step3BusinessAddress extends StatefulWidget {
  final VoidCallback nextStep;
  final TextEditingController addressController;
  final TextEditingController countryController;
  final VoidCallback pickFile;
  final PlatformFile? pickedFile;

  const _Step3BusinessAddress({
    required this.nextStep,
    required this.addressController,
    required this.countryController,
    required this.pickFile,
    this.pickedFile,
  });

  @override
  State<_Step3BusinessAddress> createState() => _Step3BusinessAddressState();
}

class _Step3BusinessAddressState extends State<_Step3BusinessAddress> {
  final _formKey = GlobalKey<FormState>();

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      widget.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Address',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 32),
            _buildBrandTextField('Address', LucideIcons.mapPin, widget.addressController),
            const SizedBox(height: 16),
            _buildCountryField(context, widget.countryController),
            const SizedBox(height: 32),
            Text(
              'Upload proof of address',
              style: GoogleFonts.montserrat(
                color: AppTheme.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utility bill or lease agreement',
              style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: widget.pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.pickedFile != null ? Colors.green.shade300 : const Color(0xFFE0DCD5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.upload,
                      color: widget.pickedFile != null ? Colors.green : AppTheme.grey.withOpacity(0.4),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.pickedFile != null ? widget.pickedFile!.name : 'Tap to upload document', 
                      style: GoogleFonts.montserrat(
                        color: widget.pickedFile != null ? Colors.green : AppTheme.grey.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            _buildBrandButton(label: 'Next', onPressed: _validateAndContinue),
          ],
        ),
      ),
    );
  }
}

class _Step4TaxInfo extends StatefulWidget {
  final VoidCallback nextStep;
  final TextEditingController taxIdController;

  const _Step4TaxInfo({
    required this.nextStep,
    required this.taxIdController,
  });

  @override
  State<_Step4TaxInfo> createState() => _Step4TaxInfoState();
}

class _Step4TaxInfoState extends State<_Step4TaxInfo> {
  final _formKey = GlobalKey<FormState>();

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      widget.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.shieldCheck, color: AppTheme.gold, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Secure Verification',
                  style: GoogleFonts.montserrat(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tax Information',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your information is encrypted and securely stored.',
              style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildBrandTextField('Tax ID / Business tax info', LucideIcons.hash, widget.taxIdController),
            const Spacer(),
            _buildBrandButton(label: 'Next', onPressed: _validateAndContinue),
          ],
        ),
      ),
    );
  }
}

class _Step5OnlinePresence extends StatefulWidget {
  final VoidCallback nextStep;
  final TextEditingController websiteController;
  final List<Map<String, String>> socialLinks;
  final ValueChanged<List<Map<String, String>>> onLinksChanged;

  const _Step5OnlinePresence({
    required this.nextStep,
    required this.websiteController,
    required this.socialLinks,
    required this.onLinksChanged,
  });

  @override
  State<_Step5OnlinePresence> createState() => _Step5OnlinePresenceState();
}

class _Step5OnlinePresenceState extends State<_Step5OnlinePresence> {
  final _linkController = TextEditingController();
  String _selectedPlatform = 'Instagram';
  
  final List<String> _platforms = ['Instagram', 'Facebook', 'TikTok', 'LinkedIn', 'YouTube', 'Twitter', 'Other'];

  void _addLink() {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;

    if (!link.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid URL')));
      return;
    }

    final newLinks = List<Map<String, String>>.from(widget.socialLinks);
    newLinks.add({'platform': _selectedPlatform, 'url': link});
    widget.onLinksChanged(newLinks);
    _linkController.clear();
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
            'Online Presence',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where can we find you?',
            style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: widget.websiteController,
            style: GoogleFonts.montserrat(color: AppTheme.black),
            decoration: InputDecoration(
              labelText: 'Website',
              labelStyle: GoogleFonts.montserrat(color: AppTheme.grey),
              prefixIcon: const Icon(LucideIcons.globe, color: AppTheme.grey, size: 20),
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
          ),
          const SizedBox(height: 24),
          Text(
            'Social Media',
            style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
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
                  controller: _linkController,
                  style: GoogleFonts.montserrat(color: AppTheme.black),
                  decoration: InputDecoration(
                    hintText: 'Link / Username',
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
              IconButton(
                onPressed: _addLink,
                icon: const Icon(LucideIcons.plusCircle, color: AppTheme.gold),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (widget.socialLinks.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DCD5)),
              ),
              child: Column(
                children: widget.socialLinks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(item['platform']!, style: GoogleFonts.montserrat(color: AppTheme.black, fontWeight: FontWeight.w500)),
                    subtitle: Text(item['url']!, style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: Icon(LucideIcons.trash2, color: AppTheme.grey.withOpacity(0.5), size: 18),
                      onPressed: () => _removeLink(index),
                    ),
                  );
                }).toList(),
              ),
            ),

          const Spacer(),
          _buildBrandButton(label: 'Next', onPressed: widget.nextStep),
        ],
      ),
    );
  }
}

class _Step6AuthorizedRep extends StatefulWidget {
  final VoidCallback nextStep;
  final TextEditingController nameController;
  final TextEditingController roleController;
  final TextEditingController emailController;

  const _Step6AuthorizedRep({
    required this.nextStep,
    required this.nameController,
    required this.roleController,
    required this.emailController,
  });

  @override
  State<_Step6AuthorizedRep> createState() => _Step6AuthorizedRepState();
}

class _Step6AuthorizedRepState extends State<_Step6AuthorizedRep> {
  final _formKey = GlobalKey<FormState>();

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      widget.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authorized Representative',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 32),
            _buildBrandTextField('Full Name', LucideIcons.user, widget.nameController),
            const SizedBox(height: 16),
            _buildBrandTextField('Role', LucideIcons.briefcase, widget.roleController),
            const SizedBox(height: 16),
            _buildBrandTextField('Contact Email', LucideIcons.mail, widget.emailController,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const Spacer(),
            _buildBrandButton(label: 'Next', onPressed: _validateAndContinue),
          ],
        ),
      ),
    );
  }
}

class _Step7Summary extends StatelessWidget {
  final VoidCallback onSubmit;
  final bool isLoading;
  final String businessName;
  final String email;
  final String country;
  final String address;
  final String phone;
  final String taxId;
  final String repName;
  final List<Map<String, String>>? socialLinks;
  final PlatformFile? proofFile;

  const _Step7Summary({
    required this.onSubmit,
    required this.isLoading,
    required this.businessName,
    required this.email,
    required this.country,
    required this.address,
    required this.phone,
    required this.taxId,
    required this.repName,
    this.socialLinks,
    this.proofFile,
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
            'Please verify your business details before submitting.',
            style: GoogleFonts.montserrat(color: AppTheme.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          _buildSummarySection('Business', [
            'Name: $businessName',
            'Email: $email',
            'Phone: $phone',
            'Country: $country',
          ]),
          
          _buildSummarySection('Address', [address]),
          
          _buildSummarySection('Legal', [
            'Tax ID: $taxId',
          ]),

          _buildSummarySection('Representative', [
            'Name: $repName',
          ]),
          
          if (socialLinks != null && socialLinks!.isNotEmpty)
             _buildSummarySection('Social Media', socialLinks!.map((e) => '${e['platform']}: ${e['url']}').toList()),

          if (proofFile != null) ...[
             const SizedBox(height: 24),
             Text(
               'PROOF OF ADDRESS',
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
                 border: Border.all(color: Colors.green.shade300),
               ),
               child: Row(
                 children: [
                   const Icon(LucideIcons.check, color: Colors.green, size: 20),
                   const SizedBox(width: 12),
                   Expanded(child: Text(proofFile!.name, style: GoogleFonts.montserrat(color: Colors.green, fontSize: 14))),
                 ],
               ),
             ),
          ],

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
