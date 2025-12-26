import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/dashboard/dashboard_screen.dart';
import 'package:flutter_application_1/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSetupScreen extends StatefulWidget {
  final String userType;

  const AccountSetupScreen({super.key, required this.userType});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _heightController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _handleCompleteSetup() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw 'User not found';

      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'setupCompleted': true,
      };

      if (widget.userType == 'model') {
        updateData.addAll({
          'height': _heightController.text.trim(),
          'location': _locationController.text.trim(),
        });
      } else {
        updateData.addAll({
          'companyName': _brandNameController.text.trim(),
          'website': _websiteController.text.trim(),
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(userType: widget.userType),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Setup',
          style: GoogleFonts.tinos(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about yourself.',
                style: GoogleFonts.tinos(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your profile to get started.',
                style: GoogleFonts.tinos(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      child: const Icon(LucideIcons.user, size: 50, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.camera, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                ),
                keyboardType: TextInputType.phone,
              ),
              if (widget.userType == 'model') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                  ),
                ),
              ],
              if (widget.userType == 'brand') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _brandNameController,
                  decoration: const InputDecoration(
                    labelText: 'Brand Name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCompleteSetup,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Complete Setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
