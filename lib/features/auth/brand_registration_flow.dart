import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/auth/registration_success_screen.dart';
import 'package:country_picker/country_picker.dart';

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
  // removed simple _socialController in favor of list
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
        withData: true, // Needed for web or direct byte access
      );

      if (result != null) {
        setState(() {
          _proofOfAddressFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);
    
    try {
      // 1. Create/Get User
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          user = userCredential.user;
      }
      
      if (user == null) throw Exception("Failed to create user");

      // 2. Upload Profile/Docs
      String? proofUrl;
      if (_proofOfAddressFile != null) {
          final ext = _proofOfAddressFile!.extension ?? 'jpg';
          final path = 'business_docs/${user.uid}/proof_of_address.$ext';
          final ref = FirebaseStorage.instance.ref().child(path);
          
          final metadata = SettableMetadata(contentType: 'application/$ext'); // Simple content type guess

          if (kIsWeb || _proofOfAddressFile!.bytes != null) {
             await ref.putData(_proofOfAddressFile!.bytes!, metadata);
          } else if (_proofOfAddressFile!.path != null) {
             await ref.putFile(File(_proofOfAddressFile!.path!), metadata);
          }
          proofUrl = await ref.getDownloadURL();
      }

      // 3. Save to Firestore
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
              message: 'Thanks for applying.\nWe’re verifying your business information.\nYou’ll receive an email once your account is approved.',
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            const Text('Step 1', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            const Text('Create Business Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            _buildTextField(
              'Business Email', 
              LucideIcons.mail, 
              widget.emailController,
              validator: (v) => v == null || v.isEmpty ? 'Email required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Password', 
              LucideIcons.lock, 
              widget.passwordController, 
              obscureText: true,
              validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _validateAndContinue, child: const Text('Next')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    IconData icon, 
    TextEditingController controller, 
    {bool obscureText = false, String? Function(String?)? validator}
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
            const Text('Business Information', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            _buildTextField('Business Name', LucideIcons.building, widget.nameController),
            const SizedBox(height: 16),
            _buildCountryField(widget.countryController),
            const SizedBox(height: 16),
            _buildTextField('Business Registration Number', LucideIcons.fileText, widget.regNumController),
            const SizedBox(height: 16),
            _buildTextField('Phone Number', LucideIcons.phone, widget.phoneController),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _validateAndContinue, child: const Text('Next')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () {
        showCountryPicker(
          context: context,
          countryListTheme: CountryListThemeData(
            flagSize: 25,
            backgroundColor: const Color(0xFF1A1A1A),
            textStyle: const TextStyle(fontSize: 16, color: Colors.white),
            bottomSheetHeight: 500,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            inputDecoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Start typing to search',
              prefixIcon: const Icon(LucideIcons.search, color: Colors.white54),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              labelStyle: const TextStyle(color: Colors.white54),
              hintStyle: const TextStyle(color: Colors.white54),
            ),
          ),
          onSelect: (Country country) {
            setState(() {
              controller.text = country.name;
            });
          },
        );
      },
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Country',
        prefixIcon: const Icon(LucideIcons.globe, color: Colors.white54, size: 20),
        suffixIcon: const Icon(LucideIcons.chevronDown, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
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
      // Ideally also check if file is picked? 
      // if (widget.pickedFile == null) { snackbar... return; }
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
            const Text('Business Address', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            _buildTextField('Address', LucideIcons.mapPin, widget.addressController),
            const SizedBox(height: 16),
            _buildCountryField(widget.countryController),
            const SizedBox(height: 32),
            const Text('Upload proof of address', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Utility bill or lease agreement', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: widget.pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.upload, color: widget.pickedFile != null ? Colors.green : Colors.white24, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      widget.pickedFile != null ? widget.pickedFile!.name : 'Tap to upload document', 
                      style: TextStyle(color: widget.pickedFile != null ? Colors.green : Colors.white24)
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _validateAndContinue, child: const Text('Next')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () {
        showCountryPicker(
          context: context,
          countryListTheme: CountryListThemeData(
            flagSize: 25,
            backgroundColor: const Color(0xFF1A1A1A),
            textStyle: const TextStyle(fontSize: 16, color: Colors.white),
            bottomSheetHeight: 500,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            inputDecoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Start typing to search',
              prefixIcon: const Icon(LucideIcons.search, color: Colors.white54),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              labelStyle: const TextStyle(color: Colors.white54),
              hintStyle: const TextStyle(color: Colors.white54),
            ),
          ),
          onSelect: (Country country) {
            setState(() {
              controller.text = country.name;
            });
          },
        );
      },
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Country',
        prefixIcon: const Icon(LucideIcons.globe, color: Colors.white54, size: 20),
        suffixIcon: const Icon(LucideIcons.chevronDown, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                const Icon(LucideIcons.shieldCheck, color: Color(0xFF6366F1), size: 28),
                const SizedBox(width: 12),
                const Text('Secure Verification', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Tax Information', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Your information is encrypted and securely stored.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            _buildTextField('Tax ID / Business tax info', LucideIcons.hash, widget.taxIdController),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _validateAndContinue, child: const Text('Next')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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

    // Simple validation
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
          const Text('Online Presence', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Where can we find you?', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          _buildTextField('Website', LucideIcons.globe, widget.websiteController),
          const SizedBox(height: 24),
          const Text('Social Media', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          // Input Row
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  controller: _linkController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Link / Username',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addLink,
                icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF6366F1)),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // List
          if (widget.socialLinks.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: widget.socialLinks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(item['platform']!, style: const TextStyle(color: Colors.white70)),
                    subtitle: Text(item['url']!, style: const TextStyle(color: Colors.white30), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.white24, size: 18),
                      onPressed: () => _removeLink(index),
                    ),
                  );
                }).toList(),
              ),
            ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: widget.nextStep, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
            const Text('Authorized Representative', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            _buildTextField('Full Name', LucideIcons.user, widget.nameController),
            const SizedBox(height: 16),
            _buildTextField('Role', LucideIcons.briefcase, widget.roleController),
            const SizedBox(height: 16),
            _buildTextField('Contact Email', LucideIcons.mail, widget.emailController,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndContinue,
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    IconData icon, 
    TextEditingController controller, 
    {String? Function(String?)? validator}
  ) {
    return TextFormField(
      controller: controller,
      validator: validator ?? (v) => v == null || v.isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
          const Text('Review Information', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Please verify your business details before submitting.', style: TextStyle(color: Colors.white54)),
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
             const Text('Proof of Address', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF1A1A1A),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.green.withOpacity(0.5)),
               ),
               child: Row(
                 children: [
                   const Icon(LucideIcons.check, color: Colors.green, size: 20),
                   const SizedBox(width: 12),
                   Expanded(child: Text(proofFile!.name, style: const TextStyle(color: Colors.green))),
                 ],
               ),
             ),
          ],

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
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
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item, style: const TextStyle(color: Colors.white)),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
