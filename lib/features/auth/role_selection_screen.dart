import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/auth/model_registration_flow.dart';
import 'package:flutter_application_1/features/auth/brand_registration_flow.dart';
import 'package:flutter_application_1/features/auth/login_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  final bool isLogin;
  const RoleSelectionScreen({super.key, this.isLogin = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.grey.withOpacity(0.15),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Caztiq',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton.icon(
          onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.arrowLeft, size: 16),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.black,
                        textStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content ──
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title — italic first word, regular second
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: isLogin ? 'Welcome ' : 'Join ',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 44,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.black,
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: isLogin ? 'Back' : 'Caztiq',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 44,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.black,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isLogin
                            ? 'Log in to your account.'
                            : 'How would you like to use the platform?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: AppTheme.grey,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // ── Role Cards ──
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final modelCard = _RoleCard(
                        icon: LucideIcons.user,
                            title: "I'm a Model",
                            description:
                                'Showcase your portfolio, receive bookings, and connect with brands looking for talent like you.',
                        onTap: () {
                          if (isLogin) {
                            Navigator.push(
                              context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LoginScreen(userType: 'model'),
                                  ),
                            );
                          } else {
                            Navigator.push(
                              context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ModelRegistrationFlow(),
                                  ),
                            );
                          }
                        },
                          );

                          final brandCard = _RoleCard(
                            icon: LucideIcons.building2,
                            title: "I'm a Brand",
                            description:
                                'Find and book talented models for your campaigns, productions, and creative projects.',
                        onTap: () {
                          if (isLogin) {
                            Navigator.push(
                              context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LoginScreen(userType: 'brand'),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BrandRegistrationFlow(),
                                  ),
                                );
                              }
                            },
                          );

                          // Side-by-side on wider screens, stacked on narrow
                          if (constraints.maxWidth > 480) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: modelCard),
                                  const SizedBox(width: 20),
                                  Expanded(child: brandCard),
                                ],
                              ),
                            );
                          } else {
                            return Column(
                              children: [
                                modelCard,
                                const SizedBox(height: 20),
                                brandCard,
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Footer link ──
                      GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RoleSelectionScreen(isLogin: !isLogin),
                            ),
                            );
                          },
                          child: Padding(
                          padding: const EdgeInsets.all(8.0),
                            child: RichText(
                              text: TextSpan(
                              text: isLogin
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                              style: GoogleFonts.montserrat(
                                color: AppTheme.grey,
                                fontSize: 14,
                              ),
                                children: [
                                  TextSpan(
                                  text: isLogin ? 'Join Now' : 'Sign in',
                                  style: GoogleFonts.montserrat(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role Card Widget ──
// Matches the React card: icon box → italic serif title → description
class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.gold.withOpacity(0.3)
                  : AppTheme.grey.withOpacity(0.15),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.gold.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? AppTheme.gold.withOpacity(0.1)
                      : AppTheme.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(widget.icon, size: 28, color: AppTheme.black),
                ),
              ),
              const SizedBox(height: 24),

              // Italic serif title
              Text(
                widget.title,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.black,
              ),
            ),
              const SizedBox(height: 8),

              // Description
              Text(
                widget.description,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppTheme.grey,
                  height: 1.6,
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}
