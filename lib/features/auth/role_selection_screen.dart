import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/auth/model_registration_flow.dart';
import 'package:flutter_application_1/features/auth/brand_registration_flow.dart';
import 'package:flutter_application_1/features/auth/login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final bool isLogin;
  const RoleSelectionScreen({super.key, this.isLogin = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        isLogin ? 'Welcome Back' : 'Join Castiq',
                        style: GoogleFonts.tinos(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isLogin ? 'Log in to your account.' : 'How would you like to use the platform?',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      _RoleButton(
                        title: isLogin ? "Login as Model" : "I'm a Model",
                        icon: LucideIcons.user,
                        onTap: () {
                          if (isLogin) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen(userType: 'model')),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ModelRegistrationFlow()),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _RoleButton(
                        title: isLogin ? "Login as Brand Manager" : "I'm a Brand / Production Manager",
                        icon: LucideIcons.briefcase,
                        onTap: () {
                          if (isLogin) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen(userType: 'brand')),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BrandRegistrationFlow()),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => RoleSelectionScreen(isLogin: !isLogin)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: RichText(
                              text: TextSpan(
                                text: isLogin ? "Don't have an account? " : "Already have an account? ",
                                style: const TextStyle(color: Colors.white70, fontSize: 16), // Increased contrast
                                children: [
                                  TextSpan(
                                    text: isLogin ? "Join Now" : "Log In",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.tinos(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(LucideIcons.arrowRight, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
